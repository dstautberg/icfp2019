require_relative './priority_queue'

class PathFinder
	attr_accessor :path

	def initialize(state, obstacles)
		@state = state
		@start = @state.worker_location
		@obstacles = obstacles
		@goal = closest_unwrapped_point
	end
	
	def find_path
		been_there = {}
    queue = PriorityQueue.new
    queue.push(1, [@state.worker_location, [], 1])
    while !queue.empty?
      spot, path_so_far, cost_so_far = queue.pop
      next if been_there[spot]
      newpath = path_so_far.dup << spot
      #binding.pry if @state.unwrapped_points.size == 11
      if spot == @goal
        @path = newpath
        return @path
      end
      been_there[spot] = true
      spots_from(spot).each {|newspot|
        next if been_there[newspot]
        newcost = cost_so_far + 1
        priority = newcost + distance(newspot, @goal)
	      #binding.pry if @state.unwrapped_points.size == 11
        queue.push(priority, [newspot, newpath, newcost])
      }
    end
    return nil
	end
	
	def closest_unwrapped_point
		closest_point, closest_distance = nil, 0
		@state.unwrapped_points.each do |p|
			d = distance(@start, p)
			if closest_point.nil? || d < closest_distance
				closest_point = p
				closest_distance = d
			end
		end
		puts "closest_unwrapped_point: #{closest_point.inspect}, at distance #{closest_distance}"
		closest_point
	end
	
	def distance(p1, p2)
		#(p2.x - p1.x).abs + (p2.y - p1.y).abs
		Math.sqrt((p2.x.to_f - p1.x.to_f)**2 + (p2.y.to_f - p1.y.to_f)**2)
	end
	
	def spots_from(spot)
		nearby = [
			Point.new(spot[0] + 1, spot[1]),
			Point.new(spot[0] - 1, spot[1]),
			Point.new(spot[0], spot[1] + 1),
			Point.new(spot[0], spot[1] - 1)
		]
		nearby.reject do |p|
			@obstacles.any? {|o| o.contains?(p) } || !@state.range.contains?(p)
		end
	end
end
