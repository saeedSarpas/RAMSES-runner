class Makefile
  def initialize
    @define = []
    @var = []
    @rule = []
    @plain = []
  end

  # it predefines name as macros, also set the name and their values globally
  def define(key, value)
    @define << { "-D#{key}" => value.to_s }
    @var << { key.to_s => value.to_s }
  end

  def set(key, value)
    if (var = @var.find { |v| v.key? key.to_s })
      var[key.to_s] = value.to_s
    else
      @var << { key.to_s => value.to_s }
    end
  end

  def extend(key, value)
    var = @var.find { |v| v.key? key.to_s }
    var[key.to_s] << " #{value}"
  end

  def rule(target, deps, *body)
    @rule << { target: target, deps: deps, body: body }
  end

  def plain(text)
    @plain << text
  end

  def write(path)
    File.open(path, 'w') do |f|
      f.write('DEFINES =')
      @define.map { |d| f.write(" #{d.keys[0]}=#{d.values[0]}") }
      f.write("\n")

      @var.map { |v| f.puts("#{v.keys[0]} = #{v.values[0]}") }

      @plain.map { |p| f.puts(p) }

      @rule.each do |r|
        f.write("#{r[:target]}: #{r[:deps]}\n")
        r[:body].map { |b| f.write("\t#{b}\n") }
      end
    end
  end
end
