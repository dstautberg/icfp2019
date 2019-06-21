require 'pry'

Point = Struct.new(:x, :y)

class Box
    attr_reader :left_bottom, :right_bottom, :right_top, :left_top
    
    def initialize(points)
        #puts "Box.new: #{points.inspect}"
        verify_point(points[0])
        verify_point(points[1])
        verify_point(points[2])
        verify_point(points[3])
        @left_bottom, @right_bottom, @right_top, @left_top = points[0], points[1], points[2], points[3]
    end
    
    def verify_point(p)
        raise "Not a point: #{p.inspect}" unless p.is_a?(Point)
    end
end

class Booster
    attr_reader :type, :point
    
    def initialize(type, point)
        raise "Bad booster type: #{type}" unless ['B','F','L','X'].include?(type)
        @type = type
        @point = point
    end
end

def parse_box(points)
    Box.new(points.split('),').map {|p| parse_point(p) })
end

def parse_point(point)
    #puts "parse_point: '#{point}'"
    split = point.gsub('(','').gsub(')','').split(',')
    Point.new(split[0].to_i, split[1].to_i)
end

def parse_booster_point(p)
    Booster.new(p[0], parse_point(p[1,10]))
end

def process(filename)
    puts "Processing #{filename}"
    s = open(filename) {|f| f.read }
    puts s
    range, worker_location, obstacles, boosters = s.split('#')
    
    range = parse_box(range)
    worker_location = parse_point(worker_location)
    obstacles = obstacles.split(';').map {|obstacle| parse_box(obstacle) }
    boosters = boosters.split(';').map {|p| parse_booster_point(p) }
    puts "range=#{range.inspect}"
    puts "worker_location=#{worker_location.inspect}"
    puts "obstacles=#{obstacles.inspect}"
    puts "boosters=#{boosters.inspect}"
    
    solution_filename = File.basename(filename, '.desc') + '.sol'
    puts "solution filename: #{solution_filename}"
    
    # TODO
end

Dir.glob('*.desc') do |filename|
    process(filename)
end
