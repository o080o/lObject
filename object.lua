local Object = {}
local metamethods = { -- all metamethods except __index
  '__add', '__call', '__concat', '__div', '__le', '__lt', '__mod', '__mul', '__pow', '__sub', '__tostring', '__unm', '__len'
} 
--function Object.class( parent, [getter], [setter] ) return Class a new Class object. When called, a Class object returns an instance of that object. 
function Object.class( parent ,getter, setter)
	local class = {}
	local objMt = class
	local classMt = {}
	if parent then
		-- in order to inherit meamethods, we have to create stub functions that will look up the metamethod in its parent.
		-- otherwise, the metamethod is not inherited, as metamethods are aquired through an equivalent of rawget(...).
		for _,metamethod in pairs(metamethods) do
			if parent[metamethod] then
				class[metamethod] = function(...) return parent[metamethod](...) end
			end
		end
		-- create a 'super' function that will call the parent/superclass's constructor, even through multiple inheritance links.
		class.super = function(self,...)
			self.super = parent.super
			parent.__init(self, ...)
			self.super = class.super
		end
		class.parent = parent --save the parent object for possible 'insanceof' like functionality
		classMt.__index = parent --use the parent table as the __index metamethod to inherit values from the parent (or the parents parent, etc through chains of __index metamethods)
	else
		classMt.__index = nil --no parent. don't inherit.
	end

	local private = {} -- private table that will be closed over in the __newindex function, and not available elsewhere

	-- a 'setter' functin can be used to store values into a private table, that can only be retreived by a corresponding 'getter' function
	if setter then
		objMt.__newindex = function(self, key)
			setter(self, private, key)
		end
	end

	-- a 'getter' functin can be used to work like __index metamethod if the key is not found in the object, or through its inheritance chain. It also has access to a private table.
	if getter then
		objMt.__index = function(self, key)
			local val = class[key] --check Class first for inheritance
			if not val then
				val = getter( self, private, key )
			end
			return val
		end
	else
		objMt.__index = class
	end


	-- setup the __call metamethod to create a new object, and use the clase's __init constructor.
	function classMt.__call(class,...)
		local self = {}
		setmetatable(self, objMt)
		self.class = class
		if self.__init then self.__init(self,...) end
		return self
	end
	return setmetatable(class,classMt), objMt
end

--function Object.clone(Object) return Object a shallow copy of this Object
function Object.clone(self)
	local clone = {}
	for k,v in pairs(self) do
		clone[k] = v
	end
	return setmetatable(clone, getmetatable(self))
end

return Object.class, Object
