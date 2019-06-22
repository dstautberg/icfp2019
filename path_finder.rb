require_relative './priority_queue'

class PathFinder
	attr_accessor :path

	def initialize(state)
		@state = state
		@start = @state.worker_location
		@goal = closest_unwrapped_point
	end
	
	def find_path
		been_there = {}
        queue = PriorityQueue.new
        queue << [1, [@state.worker_location, [], 1]]
        while !queue.empty?
          spot, path_so_far, cost_so_far = queue.next
          next if been_there[spot]
          newpath = [path_so_far, spot]
          if (spot == @goal)
            @path = []
            newpath.flatten.each_slice(2) {|i,j| @path << [i,j]}
            return @path
          end
          been_there[spot] = true
          spots_from(spot).each {|newspot|
            next if been_there[newspot]
            newcost = cost_so_far + 1
            queue << [newcost + distance(newspot, @goal), [newspot, newpath, newcost]]
          }
        end
        return nil
	end
	
	def closest_unwrapped_point
		closest_point, min_distance = nil, 0
		@state.unwrapped_points.each do |p|
			d = distance(@start, p)
			if closest_point.nil? || d < min_distance
				closest_point = p
				min_distance = d
			end
		end
		closest_distance
	end
	
	def distance(p1, p2)
		(p.x - @start.x).abs - (p.y - @start.y).abs
	end
	
	def spots_from(spot)
		nearby = [
			Point.new(spot[0] + 1, spot[1]),
			Point.new(spot[0] - 1, spot[1]),
			Point.new(spot[0], spot[1] + 1),
			Point.new(spot[0], spot[1] - 1)
		]
		nearby.reject do |p|
			@obstacles.any? {|o| o.contains?(p) } || !stage.range.contains?(p)
		end
	end
end
