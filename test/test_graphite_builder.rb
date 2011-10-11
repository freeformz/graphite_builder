require 'helper'

describe Graphite::Builder do

  describe 'when initialized with a block' do

    describe '#render' do

      describe 'when no targets are defined' do
        it 'should raise a NoTargetsDefined error' do
          Proc.new do
            Graphite::Builder.new(base_url: 'http://foo.bar/render', foo: :bar) do
              width 800
            end.render
          end.must_raise Graphite::Builder::NoTargetsDefined
        end
      end

      describe 'when a target is defined' do

        describe 'whithout using data' do
          it 'should render the correct <img/> tag' do
            Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
              target '1.2.3'
            end.render.must_equal '<img src="http://localhost/render?target=1.2.3"/>'
          end
        end

        describe 'using data' do
          it 'should render the correct <img/> tag' do
            Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
              target data :foo
              target "#{data :foo}.stuff"
            end.render.must_equal '<img src="http://localhost/render?target=bar&target=bar.stuff"/>'
          end

          describe 'setting params' do

            it 'should render the correct <img/> tag' do
              Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
                width 800
                height 200
                target 'a.b.c'
              end.render.must_equal "<img src=\"http://localhost/render?width=800&height=200&target=a.b.c\"/>"
            end
          end

          describe 'and applying a "function"' do
            it 'should render the correct <img/> tag' do
              Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
                target data :foo
                target color("#{data :foo}.stuff", 'red')
              end.render.must_equal "<img src=\"http://localhost/render?target=bar&target=color(bar.stuff,'red')\"/>"
            end
          end

          describe 'and nesting functions' do
            it 'should render the correct <img/> tag' do
              Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
                target data :foo
                target legend(color("#{data :foo}.stuff", 'red'), 'foozle')
              end.render.must_equal "<img src=\"http://localhost/render?target=bar&target=alias(color(bar.stuff,'red'),'foozle')\"/>"
            end
          end

        end

      end

      describe 'DSL functions' do

        describe 'sumSeries' do

          describe 'with a single data point' do
            it 'should render the correct <img/> tag' do
              Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
                target sumSeries('a.b.*')
              end.render.must_equal "<img src=\"http://localhost/render?target=sumSeries(a.b.*)\"/>"
            end
          end

          describe 'with multiple data points' do
            it 'should render the correct <img/> tag' do
              Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
                target sumSeries('a.b.*','a.c.*','a.d.*')
              end.render.must_equal "<img src=\"http://localhost/render?target=sumSeries(a.b.*,a.c.*,a.d.*)\"/>"
            end
          end
        end

        describe 'asPercent' do

          describe 'with a single argument' do
            it 'should raise an ArgumentError' do
              Proc.new do
                Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
                  target asPercent(1)
                end.render
              end.must_raise ArgumentError
            end
          end

          describe 'with two arguments' do
            it 'should render the correct <img/> tag' do
              Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
                target asPercent('a.b.c','a.c.b')
              end.render.must_equal "<img src=\"http://localhost/render?target=asPercent(a.b.c,a.c.b)\"/>"
            end
          end
        end

        describe 'secondYAxis' do

          describe 'with a single argument' do
            it 'should render the correct <img/> tag' do
              Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
                target secondYAxis('a.b.c')
              end.render.must_equal "<img src=\"http://localhost/render?target=secondYAxis(a.b.c)\"/>"
            end
          end

        end

        describe 'stacked' do

          describe 'with a single argument' do
            it 'should render the correct <img/> tag' do
              Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
                target stacked('a.b.c')
              end.render.must_equal "<img src=\"http://localhost/render?target=stacked(a.b.c)\"/>"
            end
          end

        end

        describe 'legend' do

          describe 'with a single argument' do
            it 'should render the correct <img/> tag' do
              Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
                target legend('a.b.c','A B C')
              end.render.must_equal "<img src=\"http://localhost/render?target=alias(a.b.c,'A+B+C')\"/>"
            end
          end

        end

        describe 'an unknown function' do

          it 'should raise an UnknownMethodFormat exception' do
            Proc.new do
              Graphite::Builder.new(base_url: 'http://localhost/render', foo: :bar) do
                target blargen(1,2,3)
              end.render
            end.must_raise Graphite::Builder::UnknownMethodFormat
          end

        end

      end

    end

  end

end
