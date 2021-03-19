require 'timeout'

describe "pool", proxy: :Pool do
  describe "Moneta::Pool" do
    # To test the pool, we create the store once and pass the same object around
    # whenever a new store is requested.
    before :context do
      tempdir = @pool_tempdir = Dir.mktmpdir
      @pool_store = Moneta.build do
        use :Pool, max: 2, timeout: 5 do
          adapter :File, dir: tempdir
        end
      end
    end

    # Tell the manager to close all open stores
    after :context do
      @pool_store.stop
      FileUtils.remove_dir(@pool_tempdir)
    end

    moneta_build { @pool_store }
    moneta_specs ADAPTER_SPECS.with_each_key

    it "raises an error on check-out the builder fails" do
      store = Moneta.build do
        use :Pool do
          adapter(Class.new do
            def initialize(options = {})
              raise "boom"
            end
          end)
        end
      end

      expect { store['x'] }.to raise_error "boom"
    end
  end

  describe "Moneta::Pool::PoolManager" do
    let :builder do
      double('builder').tap do |builder|
        i = -1
        allow(builder).to receive(:build) do
          [stores[i += 1]]
        end
      end
    end

    let(:stores) { (0...num).map { |i| double("store#{i}") } }

    after { subject.kill! }

    shared_examples :no_ttl do
      context "with one store" do
        let(:num) { 1 }

        it "never expires the store" do
          store = stores.first
          expect(builder).to receive(:build).once
          expect(subject.check_out).to be store
          expect(subject.stats).to include(stores: 1, available: 0)
          expect(subject.check_in(store)).to eq nil
          expect(subject.stats).to include(stores: 1, available: 1)
          sleep 1
          expect(subject.stats).to include(stores: 1, available: 1)
          expect(subject.check_out).to be store
          expect(subject.check_in(store)).to eq nil
        end
      end
    end

    shared_examples :no_max do
      context "with 1,000 stores" do
        let(:num) { 1_000 }

        it "never blocks" do
          # Check out 1000 stores in 1000 threads
          threads = (0...num).map do
            Thread.new { subject.check_out }
          end
          expect(threads.map(&:value)).to contain_exactly(*stores)
          expect(subject.stats).to include(stores: num, available: 0, waiting: 0)

          # Check in the first 50
          expect(stores.take(50).map { |store| subject.check_in(store) }).to all(be nil)
          expect(subject.stats).to include(stores: num, available: 50, waiting: 0)

          # Now check those 50 out again
          threads = (0...50).map do
            Thread.new { subject.check_out }
          end
          expect(threads.map(&:value)).to contain_exactly(*stores.take(50))

          # Finally check in all stores
          expect(stores.map { |store| subject.check_in(store) }).to all(be nil)
        end
      end
    end

    shared_examples :min do |min|
      describe "initial number of stores" do
        let(:num) { min }

        it "starts with #{min} available stores" do
          expect(subject.stats).to include(stores: min, available: min)
          expect((0...min).map { subject.check_out }).to contain_exactly(*stores)
        end
      end
    end

    shared_examples :max do |max, timeout: 5|
      describe "maximum number of stores" do
        let(:num) { max }

        after do
          expect(stores.map { |store| subject.check_in(store) }).to all be_nil
        end

        it "blocks after #{max} stores have been created" do
          # All stores are checked out
          expect(max.times.map { subject.check_out }).to contain_exactly(*stores)

          # Launch threads that make checkout requests (in order).  These will
          # all block.
          threads = max.times.map { Thread.new { subject.check_out } }
          Timeout.timeout(timeout) { Thread.pass until subject.stats[:waiting] == max }
          expect(threads).to all be_alive

          # Check all stores except the first one back in.  This will cause all
          # but one of the threads to return
          expect(stores.drop(1).map { |store| subject.check_in(store) }).to all be_nil
          Timeout.timeout(timeout) { Thread.pass until threads.select(&:alive?).length == 1 }
          expect(subject.stats).to include(waiting: 1)

          # Ensure that the stores that were checked back in are the ones that
          # were given to the waiting threads.
          alive, dead = threads.partition(&:alive?)
          expect(dead.map(&:value)).to contain_exactly(*stores.drop(1))

          # Check the last store back in and make sure it goes to the last
          # waiting thread.
          last_thread = alive.first
          expect(subject.check_in(stores.first)).to eq nil
          Timeout.timeout(timeout) { Thread.pass while last_thread.alive? }
          expect(subject.stats).to include(waiting: 0)
          expect(last_thread.value).to be stores.first
        end
      end
    end

    shared_examples :ttl do |ttl, min: 0, max: nil|
      describe "closing stores after TTL expiry" do
        let(:num) { max || min + 10 }

        it "closes unneeded stores after ttl" do
          stores.each do |store|
            allow(store).to receive(:close)
          end

          Timeout.timeout(5) { Thread.pass until subject.stats[:stores] == min }
          expect(stores.length.times.map { subject.check_out }).to contain_exactly(*stores)
          expect(subject.stats).to include(stores: num, available: 0)
          expect(stores.map { |store| subject.check_in(store) }).to all be_nil
          expect(subject.stats).to include(stores: num, available: num)
          sleep ttl
          expect(subject.stats).to include(stores: min, available: min)
        end
      end
    end

    shared_examples :ttl_with_nonzero_min do |ttl:, min:, max: nil|
      describe "TTL check" do
        let(:num) { max || min + 10 }

        # This is testing that a very specific bug is fixed - see
        # https://github.com/moneta-rb/moneta/issues/197.  A better long-term
        # solution would be to have more granular tests of the functions in the
        # PoolManager
        it "doesn't cause a busy-loop when there are available stores" do
          # Check a store in and out - now the manager needs to decide whether to close
          # stores after ttl seconds.
          store = subject.check_out
          subject.check_in(store)
          sleep ttl
          expect(subject.stats[:available]).to be > 0

          # needs to be less than the TTL, but otherwise not important.
          sleep_time = ttl / 2.0
          sleep sleep_time

          # during the sleep, the pool manager should have been idle.
          expect(subject.stats[:idle_time]).to be >= sleep_time
        end
      end
    end

    shared_examples :timeout do |timeout, max:|
      describe "raising an error after timeout" do
        let(:num) { max }

        it "raises a timeout error after waiting too long" do
          expect((0...num).map { subject.check_out }).to contain_exactly(*stores)
          # One extra checkout request in a separate thread
          t = Thread.new do
            Thread.current.report_on_exception = false if Thread.current.respond_to? :report_on_exception
            subject.check_out
          end
          Timeout.timeout(timeout) { Thread.pass until subject.stats[:waiting] == 1 }
          expect(subject.stats[:longest_wait]).to be_a Time
          expect(t).to be_alive
          sleep timeout
          Timeout.timeout(timeout) { Thread.pass while t.alive? }
          expect { t.value }.to raise_error Moneta::Pool::TimeoutError
          expect(subject.stats).to include(waiting: 0, longest_wait: nil)
          expect(stores.map { |store| subject.check_in store }).to all be_nil
        end
      end
    end

    context "with default arguments" do
      subject { Moneta::Pool::PoolManager.new(builder) }
      after { subject.kill! }

      include_examples :no_ttl
      include_examples :no_max
      include_examples :min, 0
    end

    context "with max: 10, timeout: 4" do
      subject { Moneta::Pool::PoolManager.new(builder, max: 10, timeout: 4) }
      after { subject.kill! }

      include_examples :no_ttl
      include_examples :max, 10, timeout: 4
      include_examples :min, 0
      include_examples :timeout, 4, max: 10
    end

    context "with min: 10" do
      subject { Moneta::Pool::PoolManager.new(builder, min: 10) }
      after { subject.kill! }

      include_examples :no_max
      include_examples :min, 10
    end

    context "with ttl: 1" do
      subject { Moneta::Pool::PoolManager.new(builder, ttl: 1) }
      after { subject.kill! }

      include_examples :ttl, 1, min: 0
    end

    context "with min: 10, max: 20, ttl: 1, timeout: 4" do
      subject { Moneta::Pool::PoolManager.new(builder, min: 10, max: 20, ttl: 1, timeout: 4) }
      after { subject.kill! }

      include_examples :min, 10
      include_examples :max, 20, timeout: 4
      include_examples :ttl, 1, min: 10, max: 20
      include_examples :ttl_with_nonzero_min, ttl: 1, min: 10, max: 20
      include_examples :timeout, 4, max: 20
    end

    context "with min: 10, max: 10, ttl: 2, timeout: 4" do
      subject { Moneta::Pool::PoolManager.new(builder, min: 10, max: 10, ttl: 2, timeout: 4) }
      after { subject.kill! }

      include_examples :min, 10
      include_examples :max, 10, timeout: 4
      include_examples :ttl, 2, min: 10, max: 10
      include_examples :ttl_with_nonzero_min, ttl: 2, min: 10, max: 10
      include_examples :timeout, 4, max: 10
    end

    describe '#check_out' do
      subject { Moneta::Pool::PoolManager.new(builder, max: 1, timeout: 5) }
      after { subject.kill! }

      let(:num) { 1 }

      it 'yields the store to requesters first come, first served' do
        store = stores.first
        procs = (0...10)
          .map { |i| double("proc#{i}") }
          .each { |p| expect(p).to receive(:call).with(store).ordered }

        # Each thread stops immediately after starting.  We can then ensure
        # that each checkout is called in order.
        threads = procs.map do |p|
          Thread.new do
            Thread.stop
            p.call(subject.check_out)
          end
        end

        Timeout.timeout(5) { Thread.pass until threads.all?(&:stop?) }

        # The first thread should return immediately after waking
        threads.first.wakeup
        Timeout.timeout(5) { threads.first.join }

        # Wait for the remaining threads to block, one at a time.
        threads.drop(1).each_with_index do |thread, i|
          thread.wakeup
          Timeout.timeout(5) { Thread.pass until subject.stats[:waiting] == i + 1 }
        end

        # The remaining threads should be waiting for the store to be checked back in
        expect(threads.drop(1)).to all be_alive
        expect(subject.stats).to include(waiting: 9)

        Timeout.timeout(5) do
          threads.each do |t|
            t.join
            subject.check_in(store)
          end
        end
      end

      it "raises a ShutdownError if the pool is stopped while waiting for a store" do
        # Exhaust the pool
        store = stores.first
        allow(store).to receive(:close).once
        expect(subject.check_out).to eq store

        # Simulate a new thread requesting a check-out
        t1 = Thread.new do
          Thread.current.report_on_exception = false if Thread.current.respond_to? :report_on_exception
          subject.check_out
        end
        Timeout.timeout(5) { Thread.pass until subject.stats[:waiting] > 0 }
        expect(t1).to be_alive

        # Meanwhile in another thread, the pool is stopped.
        t2 = Thread.new { subject.stop }

        # The requesting thread should error out immediately
        expect { t1.value }.to raise_error Moneta::Pool::ShutdownError

        # In this thread we return the store to the pool, allowing graceful shutdown to complete.
        subject.check_in(store)
        expect(t2.value).to be_nil
      end

      it "raises a ShutdownError if a the pool is stopped before requesting a store" do
        subject.stop
        expect { subject.check_out }.to raise_error Moneta::Pool::ShutdownError
      end
    end
  end
end
