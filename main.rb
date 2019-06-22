require 'pry'

Point = Struct.new(:x, :y)
MapState = Struct.new(:worker_location, :worker_direction, :manipulator_points, :unwrapped_points, :boosters_held, :boosters_active, :moves, :maps)

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
    
    def contains?(point)
        point.x >= left_bottom.x && point.y >= left_bottom.y && point.x <= right_top.x && point.y <= right_top.y
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
    @range, worker_location, @obstacles, boosters = s.split('#')
    
    @range = parse_box(@range)
    worker_location = parse_point(worker_location)
    @obstacles = @obstacles.nil? ? [] : @obstacles.split(';').map {|obstacle| parse_box(obstacle) }
    boosters = boosters.nil? ? [] : boosters.split(';').map {|p| parse_booster_point(p) }
    puts "@range=#{@range.inspect}"
    puts "worker_location=#{worker_location.inspect}"
    puts "@obstacles=#{@obstacles.inspect}"
    puts "boosters=#{boosters.inspect}"
    
    solution_filename = File.basename(filename, '.desc') + '.sol'
    puts "solution filename: #{solution_filename}"
    
    # I think some recursion is in order.
    # That means I am going to need to represent the state of the map.
    # Figure out how many filled and/or unfilled squares there are.
    # Go through possible moves: up, down, left, right, do nothing, turn clockwise, turn counterclockwise, 
    # attach a new manipulator (takes relative x, y coordinates, so that will complicate things), 
    # attach fast wheels, start using a drill.
    # It would be helpful to be able to detect redundant states, or maybe keep a heuristic on the progress I'm making,
    # and bail on the branch of activity if I haven't made progress in a while.
    # Probably moving forward should always be what I try first, as long as I'm not blocked.
    # For my first phase, I think I will ignore the boosters, but I need to keep things flexible.
    # So the manipulator points can change, the movement speed can change, and I may be able to drill through obstacles,
    # but not move outside the map.
    
    # figure out unwrapped points, initial position and manipulator points are wrapped
    # try moving forward
        # return if blocked
        # update unwrapped points
        # pick up booster if I'm one on
        # check how long it's been since I made progress
        # call recursive method
    # try turning cw    
        # update unwrapped points
        # check how long it's been since I made progress
    # try turning ccw

    state = MapState.new
    state.worker_location = worker_location
    state.moves = []
    # The initial configuration of the manipulators is always the same and is described by the squares
    # with coordinates [(x + 1,y), (x + 1,y + 1), (x + 1,y − 1)], where (x,y) is the location of the worker
    state.manipulator_points = [
        Point.new(worker_location.x+1, worker_location.y),
        Point.new(worker_location.x+1, worker_location.y+1),
        Point.new(worker_location.x+1, worker_location.y-1)
    ]
    state.worker_direction = Point.new(1, 0) # positive x direction
    state.unwrapped_points = []
    0.upto(@range.right_top.x) do |x|
        0.upto(@range.right_top.y) do |y|
            point = Point.new(x, y)
            if ([state.worker_location] + state.manipulator_points).include?(point)
                puts "Covered by worker: #{point.inspect}"
            elsif @obstacles.any? {|o| o.contains?(point) }
                puts "Covered by obstacle: #{point.inspect}"
            else    
                state.unwrapped_points << point
            end
        end
    end
    puts "Starting unwrapped points: #{state.unwrapped_points.inspect}"
    state.maps = [draw_map(state)]
    
    @actions = [
        :up, :down, :left, :right,
        #:nothing, :turn_cw, :turn_ccw,
        #:attach_arm, :attach_wheel, :use_drill
    ]
    @actions.each do |action|
        recurse(state, action)
    end
    
    puts "*** Result ***"
    puts @success.inspect
end

def recurse(state, action)
    #puts "***************** recurse"
    #puts "worker_location=#{state.worker_location.inspect}"
    #puts "worker_direction=#{state.worker_direction.inspect}"
    #puts "manipulator_points=#{state.manipulator_points.inspect}"
    #puts "unwrapped_points.size=#{state.unwrapped_points.size}"
    #puts "moves=#{state.moves.inspect}"
    #puts "moves.size=#{state.moves.size}"
    #draw_map(state)
    #puts "action=#{action}"
    result = case action
        when :up
            move(state, 0, 1, 'W')
        when :down
            move(state, 0, -1, 'S')
        when :left
            move(state, -1, 0, 'A')
        when :right
            move(state, 1, 0, 'D')        
        else
            raise "Unkown action: #{action}"
    end
    #puts "After move #{action}:"
    #puts "worker_location=#{state.worker_location.inspect}"
    #puts "worker_direction=#{state.worker_direction.inspect}"
    #puts "manipulator_points=#{state.manipulator_points.inspect}"
    #puts "unwrapped_points.size=#{state.unwrapped_points.size}"
    #puts "moves=#{state.moves.inspect}"
    #puts "moves.size=#{state.moves.size}"
    #state.maps << draw_map(state)
    #state.maps.each {|m| puts "-----\n#{m}" }
    #puts "-----"
    
    if state.unwrapped_points.empty?
        if @success.nil? || (@success.size > state.moves.size)
            @success = state.moves 
            puts "Found new success state at #{state.moves.size} moves: #{state.moves}"
        else
            puts "Found success state at #{state.moves.size} moves, but it was not shorter"
        end
    elsif too_many_moves(state)
        #puts "Giving up after #{state.moves.size} moves"
        return
    elsif result == :blocked
        #puts "Move #{action} is blocked"
        return
    else
        @actions.each do |an|
            new_state = MapState.new(
                state.worker_location.dup,
                state.worker_direction.dup,
                clone(state.manipulator_points),
                state.unwrapped_points&.dup,
                state.boosters_held&.dup,
                state.boosters_active&.dup,
                state.moves&.dup,
                state.maps&.dup
            )
            recurse(new_state, an)
        end
    end
end

def clone(a)
    Marshal.load(Marshal.dump(a))
end

def too_many_moves(state)
   return true if @success && @success.size < state.moves.size 
   return true if state.moves.size > ((@range.right_top.x+1) * (@range.right_top.y+1))
   false
end

def move(state, x, y, move_code)
    p1 = state.worker_location
    p2 = Point.new(p1.x + x, p1.y + y)
    if !@range.contains?(p2) || @obstacles.any? {|ob| ob.contains?(p2) }
        return :blocked
    end
    
    state.worker_location.x = p2.x
    state.worker_location.y = p2.y
    state.unwrapped_points.delete(state.worker_location)
    state.manipulator_points.each do |mp|
        mp.x = mp.x + x
        mp.y = mp.y + y
        # TODO: check if worker reach is blocked by obstacle
        state.unwrapped_points.delete(mp)
    end            
    state.moves << move_code
end

def draw_map(state)
    map = ''
    @range.right_top.y.downto(0).each do |y|
        0.upto(@range.right_top.x) do |x|
            p = Point.new(x, y)
            if state.worker_location == p
                map += '+'
            elsif state.manipulator_points.include?(p)
                map += '-'
            elsif state.unwrapped_points.include?(p)
                map += 'O'
            else
                map += 'X'
            end
        end
        map += "\n"
    end
    map
end

Dir.glob('*.desc') do |filename|
    process(filename)
end

def test
    box = Box.new([Point.new(1, 2), Point.new(5, 2), Point.new(5, 6), Point.new(5, 2)])
    puts "box contains 1, 1: #{box.contains?(Point.new(1, 1))}"
    puts "box contains 1, 2: #{box.contains?(Point.new(1, 2))}"
    puts "box contains 1, 6: #{box.contains?(Point.new(1, 6))}"
    puts "box contains 1, 7: #{box.contains?(Point.new(1, 7))}"
    puts "box contains 0, 3: #{box.contains?(Point.new(0, 3))}"
    puts "box contains 1, 3: #{box.contains?(Point.new(1, 3))}"
    puts "box contains 5, 3: #{box.contains?(Point.new(5, 3))}"
    puts "box contains 6, 3: #{box.contains?(Point.new(6, 3))}"
end

#test
