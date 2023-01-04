local tween_service = game:GetService("TweenService")
local user_input_service = game:GetService("UserInputService")
local run_service = game:GetService("RunService")
local core_gui = game:GetService("CoreGui")
local test_service = game:GetService("TestService")
local player_service = game:GetService("Players")

local player = player_service.LocalPlayer
local player_gui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local lib = {}
local utility = {}
local connections_names = {}
local file_system = {}
local theme_gui_objects = {} -- theme_gui_objects[GuiObject] = "type"
local closing_callbacks = {}
local closing = false

local blank = function() return end -- blank function
local env = (getgenv and getgenv() or getfenv(0))

local current_theme = { -- copied the way kavo does it
	SchemeColor = Color3.fromRGB(64, 64, 64), -- button highlighting, icons, scrollbar 
	Background = Color3.fromRGB(24, 24, 24), -- window background
	Header = Color3.fromRGB(18, 18, 18), -- top & tabs background color
	TextColor = Color3.fromRGB(255,255,255), -- text color
	ElementColor = Color3.fromRGB(15, 15, 15) -- librarys things such as sliders, buttons, etc
}

utility.error_type = {
	[0] = function(...) if env["info"] then env["info"](table.concat({...}, "\t")) else test_service:Message(table.concat({...}, "\t")) end end,
	[1] = print,
	[2] = warn,
	[3] = error,
}

utility.primary_font = {	
	black = Enum.Font.SourceSansBold,
	bold = Enum.Font.SourceSansSemibold,
	standard = Enum.Font.SourceSans,
	light = Enum.Font.SourceSansLight,
}

utility.preset_themes = { -- I got this from kavo :troll:
	dark = {
		SchemeColor = Color3.fromRGB(64, 64, 64),
		Background = Color3.fromRGB(24, 24, 24),
		Header = Color3.fromRGB(18, 18, 18),
		TextColor = Color3.fromRGB(255,255,255),
		ElementColor = Color3.fromRGB(15, 15, 15)
	};

	light = {
		SchemeColor = Color3.fromRGB(150, 150, 150),
		Background = Color3.fromRGB(255,255,255),
		Header = Color3.fromRGB(200, 200, 200),
		TextColor = Color3.fromRGB(0,0,0),
		ElementColor = Color3.fromRGB(224, 224, 224)
	};

	synapse = {
		SchemeColor = Color3.fromRGB(46, 48, 43),
		Background = Color3.fromRGB(13, 15, 12),
		Header = Color3.fromRGB(36, 38, 35),
		TextColor = Color3.fromRGB(152, 99, 53),
		ElementColor = Color3.fromRGB(24, 24, 24)
	};

	ocean = {
		SchemeColor = Color3.fromRGB(86, 76, 251),
		Background = Color3.fromRGB(26, 32, 58),
		Header = Color3.fromRGB(38, 45, 71),
		TextColor = Color3.fromRGB(200, 200, 200),
		ElementColor = Color3.fromRGB(38, 45, 71)
	};
	
	blood = {
		SchemeColor = Color3.fromRGB(227, 27, 27),
		Background = Color3.fromRGB(10, 10, 10),
		Header = Color3.fromRGB(5, 5, 5),
		TextColor = Color3.fromRGB(255,255,255),
		ElementColor = Color3.fromRGB(20, 20, 20)
	};
	
	grape = {
		SchemeColor = Color3.fromRGB(166, 71, 214),
		Background = Color3.fromRGB(64, 50, 71),
		Header = Color3.fromRGB(36, 28, 41),
		TextColor = Color3.fromRGB(255,255,255),
		ElementColor = Color3.fromRGB(74, 58, 84)
	};
	
	midnight = {
		SchemeColor = Color3.fromRGB(26, 189, 158),
		Background = Color3.fromRGB(44, 62, 82),
		Header = Color3.fromRGB(57, 81, 105),
		TextColor = Color3.fromRGB(255, 255, 255),
		ElementColor = Color3.fromRGB(52, 74, 95)
	};
	
	sentinel = {
		SchemeColor = Color3.fromRGB(230, 35, 69),
		Background = Color3.fromRGB(32, 32, 32),
		Header = Color3.fromRGB(24, 24, 24),
		TextColor = Color3.fromRGB(119, 209, 138),
		ElementColor = Color3.fromRGB(24, 24, 24)
	};
	
	serpent = {
		SchemeColor = Color3.fromRGB(0, 166, 58),
		Background = Color3.fromRGB(31, 41, 43),
		Header = Color3.fromRGB(22, 29, 31),
		TextColor = Color3.fromRGB(255,255,255),
		ElementColor = Color3.fromRGB(22, 29, 31)
	};
}


function utility.tween_obj(obj, properties, ...) --- time, style, direction
	local arguments = table.pack(...)

	arguments[1] = arguments[1] or 1
	arguments[2] = arguments[2] or Enum.EasingStyle.Quad
	arguments[3] = arguments[3] or Enum.EasingDirection.Out

	local t = tween_service:Create(obj, TweenInfo.new(table.unpack(arguments)), properties)
	t:Play()
	t:Destroy()
end

function utility.call_function(callback, ...)
	callback = (type(callback) == "function" and callback or nil)
	
	local success, err_msg = false, "callback doesn't exist!"
	if callback then
		success, err_msg = pcall(callback, ...)
	end
	utility.assert(success, err_msg, 2);
	
	return success, err_msg
end

function utility.assert(obj, msg, err_type) --- time, style, direction
	err_type = err_type or 2
	err_type = (err_type > table.maxn(utility.error_type) and 2 or err_type < table.maxn(utility.error_type) and 2 or err_type)
	err_type = utility.error_type[err_type]
	
	if (obj == nil or obj == false) then
		err_type(msg);
	end
end


function utility.create_connection_table(connection_name)
	if connections_names[connection_name] then
		return connections_names[connection_name]
	end

	local meta_table = setmetatable({connections = {}}, {
		__index = function(self, idx)
			idx = string.lower(tostring(idx))

			if idx == "dispose" then
				return function(t)
					local connections = rawget(self, "connections")

					for i, connection in pairs(connections) do
						connection:Disconnect();
					end
				end
			elseif idx == "connect" then
				return function(t, event, ev_function)
					local connections = rawget(self, "connections")
					local index = #connections + 1
					local event = event:Connect(ev_function)
					
					rawset(connections, index, event)

					return setmetatable({}, {__index = function(t, idx)
						idx = string.lower(tostring(idx))

						if idx == "disconnect" then
							return function(t)
								event:Disconnect()
								rawset(connections, index, nil)
							end
						elseif idx == "connected" then
							return event.Connected
						end

						return nil
					end})
				end
			end

			return nil
		end,

		__newindex = function(self, idx, val) return end,
		__metatable = function(self) return table.freeze({}) end
	})

	connections_names[connection_name] = meta_table
	return meta_table
end

function utility.create_instance(class_name, properties, children)
	properties = properties or {}
	children = children or {}
	
	local instance = nil
	
	local s, e = pcall(function()
		instance = Instance.new(class_name)
	end)
	utility.assert(instance, "classname not found!", 2)
	
	if instance then
		for prop_name, prop_val in pairs(properties) do  -- parent goes last!
			if prop_name ~= "Parent" then
				instance[prop_name] = prop_val
			end
		end
		
		for index, child_inst in pairs(children) do 
			utility.assert(type(child_inst) == "userdata", "child is not a instance!", 2)
			if type(child_inst) == "userdata" then
				child_inst.Parent = instance
			end
		end
		
		if properties["Parent"] ~= nil then
			utility.assert(type(properties["Parent"]) == "userdata", "Parent is not a instance!", 2)
			if type(properties["Parent"]) == "userdata" then
				instance.Parent = properties["Parent"]
			end
		end
		
		return instance
	end
	
	return nil
end

function utility:drag_gui(frame, parent)
	parent = parent or frame
	
	local dragging = false
	local dragInput, mousePos, framePos
	
	local main_connections = utility.create_connection_table("tab_button_connections") -- I know this is not really tabs but I want these to go with tabs yk?
	
	main_connections:Connect(frame.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = parent.Position

			local c1; c1 = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					c1:Disconnect()
				end
			end)
		end
	end)
	
	
	main_connections:Connect(frame.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	main_connections:Connect(user_input_service.InputChanged, function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			utility.tween_obj(parent, { Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)}, .2)
		end
	end)
end

local keybinds = {}
local ended = {}
local init = false
function utility.initialize_keybind()
	if not init then
		init = true
		
		local main_connections = utility.create_connection_table("tab_button_connections") -- I know this is not really tabs but I want these to go with tabs yk?
		
		main_connections:Connect(user_input_service.InputBegan, function(input, chat)
			if (chat) then return end
			if keybinds[input.KeyCode] then
				for i, key_func in pairs(keybinds[input.KeyCode]) do
					utility.call_function(key_func)
				end
			end
		end)

		main_connections:Connect(user_input_service.InputEnded, function(input, chat)
			if (chat) then return end
			if ended[input.KeyCode] then
				for i, key_func in pairs(ended[input.KeyCode]) do
					utility.call_function(key_func)
				end
			end
		end)
	end 
end

function utility.insert_key(kcode, ktype, kfunc)
	ktype = ktype or 0
	ktype = math.clamp(ktype, 0, 1)
	
	local enabled = true
	
	local func = function()
		if enabled then
			utility.call_function(kfunc)
		end
	end
	local tab = (ktype == 0 and keybinds or ktype == 1 and ended)
	
	if (tab[kcode] == nil) then 
		tab[kcode] = {}
		tab = tab[kcode]
	end
	
	table.insert(tab, func)
	local index = table.find(tab, func)
	
	return {
		disable = function()
			enabled = false
		end,
		
		enable = function()
			enabled = true
		end,
		
		kill = function()
			table.remove(index)
		end
	}
end

-- doing env cause I hate errors in studio
file_system.writefile = (env["writefile"] and env["writefile"] or blank)
file_system.readfile = (env["readfile"] and env["readfile"] or blank)
file_system.isfile = (env["isfile"] and env["isfile"] or blank)
file_system.makefolder = (env["makefolder"] and env["makefolder"] or blank)
file_system.isfolder = (env["isfolder"] and env["isfolder"] or blank)

local function get_today()
	return math.floor(((os.time()/60)/60)/24)
end

local function get_random_number(min, max, seed)
	local rnd = Random.new((seed or nil))
	return rnd:NextInteger(min, max)
end

local function get_randomized_name(seed)
	seed = seed or get_today()
	return tostring(get_random_number(100000, 1000000, seed/5)) .. tostring(get_random_number(100000, 1000000, seed*5))
end

lib.file_system = file_system
function lib.new(lib_name, theme_list) -- im using ';' to indicate the end of the 'create_instance' function
	theme_list = theme_list or utility.preset_themes.darktheme
	local window = {}
	local create_instance = utility.create_instance
	local lowered_theme = string.lower(tostring(theme_list))
	
	if utility.preset_themes[lowered_theme] then
		current_theme = utility.preset_themes[lowered_theme]
	elseif type(theme_list) == "table" then
		for theme_type, theme_data in pairs(theme_list) do
			if current_theme[theme_type] then
				current_theme[theme_type] = theme_data
			end
		end
	else
		theme_list = utility.preset_themes.darktheme
	end
	
	local tab_button_connections = utility.create_connection_table("tab_button_connections")
	local main_connections = utility.create_connection_table("main_connections")
	utility.initialize_keybind()
	

	local gui_parent = (run_service:IsStudio() and player_gui or core_gui)
	local gui = (gui_parent:FindFirstChild(get_randomized_name(get_today() - 2)) or gui_parent:FindFirstChild(get_randomized_name(get_today() - 1)) or gui_parent:FindFirstChild(get_randomized_name(get_today())) or gui_parent:FindFirstChild(get_randomized_name(get_today() + 1)) )
	if gui == nil then
		gui = create_instance("ScreenGui", {
			Name = get_randomized_name(),
			Parent = gui_parent,
			DisplayOrder = 1999999900,
			ResetOnSpawn = false
		});
	end
	
	local frame_window = create_instance("Frame", {
		Name = "window",
		Parent = gui,
		BackgroundColor3 = current_theme.Background,
		Position = UDim2.new(0.5, -335.75, 0.5, -226),
		Size = UDim2.fromOffset(655, 355)
	}, {
		create_instance("UICorner", {
			CornerRadius = UDim.new(0.025, 0)
		}),
		
		create_instance("ImageLabel", {
			Name = "glow",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(-0.05, -0.05),
			Size = UDim2.fromScale(1.105, 1.105),
			ZIndex = -1,
			Image = "rbxassetid://9735214978",
			ImageColor3 = Color3.fromRGB(0, 0, 0)
		}),
		
		create_instance("Frame", {
			Name = "tabs",
			BackgroundColor3 = current_theme.Header,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 0.102),
			Size = UDim2.fromScale(0.263, 0.897),
			ZIndex = 2
		}, {
			create_instance("UICorner", {
				CornerRadius = UDim.new(0.05, 0)
			}),
			
			create_instance("ScrollingFrame", { 
				Name = "content",
				Active = true,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.006, 0.042),
				Size = UDim2.fromScale(1.058, 0.94),
				TopImage = "rbxassetid://8214610187",
				MidImage = "rbxassetid://8214611131",
				BottomImage = "rbxassetid://8214604701",
				ScrollBarThickness = 6,
				ScrollBarImageColor3 = current_theme.SchemeColor,
				CanvasSize = UDim2.fromScale(0, 0),
				ZIndex = 3
			},{
				create_instance("UIListLayout", {
					Padding = UDim.new(0, 3),
					SortOrder = Enum.SortOrder.LayoutOrder
				});

				create_instance("UIPadding", {
					PaddingLeft = UDim.new(0, 10)
				});
			}),
			
			create_instance("Frame", {
				Name = "hide",
				BackgroundColor3 = Color3.fromRGB(18, 18, 18),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.871, 0.939),
				Size = UDim2.fromScale(0.122, 0.061)
			})
		}),
		
		create_instance("Frame", {
			Name = "top",
			BackgroundColor3 = current_theme.Header,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.fromScale(1, 0.122),
			ZIndex = 100
		}, {
			create_instance("UICorner", {
				CornerRadius = UDim.new(0.15, 0)
			}),
			
			create_instance("TextLabel", {
				Name = "title",
				Text = lib_name,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.017, 0.258),
				Size = UDim2.fromScale(0.458, 0.577),
				Font = utility.primary_font.standard,
				TextColor3 = current_theme.TextColor,
				TextScaled = true,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 101
			}),
			
			create_instance("Frame", {
				Name = "hide",
				BackgroundColor3 = Color3.fromRGB(18, 18, 18),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.871, 0.939),
				Size = UDim2.fromScale(0.122, 0.061)
			})
		}),
		
		create_instance("Frame", {
			Name = "pages",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.252, 0.122),
			Size = UDim2.fromScale(0.748, 0.875),
			ClipsDescendants = true
		}, {
			create_instance("UIPageLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				EasingDirection = Enum.EasingDirection.InOut,
				SortOrder = Enum.SortOrder.LayoutOrder,
				EasingStyle = Enum.EasingStyle.Quad,
				TweenTime = 0.25
			})
		}),
	});
	
	local tabs = frame_window.tabs
	local content = tabs.content
	local top = frame_window.top
	local title = top.title;
	local tab_content = frame_window.pages
	
	theme_gui_objects[frame_window] = "Background"
	theme_gui_objects[frame_window.glow] = "Background"
	theme_gui_objects[tabs] = "Header"
	theme_gui_objects[tabs.hide] = "Header"
	theme_gui_objects[top] = "Header"
	theme_gui_objects[top.hide] = "Header"
	theme_gui_objects[title] = "TextColor"
	theme_gui_objects[content] = "SchemeColor"
	
	
	utility.drag_gui(top, frame_window)
	
	local current_tab
	function window:new_tab(tab_name, icon)
		local tab = {}
		
		icon = tonumber(icon)
		if icon then
			icon = "rbxassetid://" .. tostring(icon)
		end
		
		if content:FindFirstChild(tab_name) then
			utility.assert(false, "page already exist!", 2)
			return {}
		end
		
		local tab_page_layout = tab_content.UIPageLayout
		
		local tab_button = create_instance("TextButton", {
			Name = tab_name,
			Parent = content,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 35),
			ZIndex = 50,
			AutoButtonColor = false,
			Font = utility.primary_font.standard,
			Text = ""
		}, {
			create_instance("Frame", {
				Name = "bg",
				BackgroundColor3 = current_theme.SchemeColor,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 3
			},{
				create_instance("UICorner", {
					CornerRadius = UDim.new(0.2, 0)
				});
			});
			
			create_instance("ImageLabel", {
				Name = "Icon",
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.006, 0.028),
				Size = UDim2.fromScale(0.189, 0.914),
				ZIndex = 5,
				Image = icon,
				Visible = (icon ~= nil)
			});
			
			create_instance("TextLabel", {
				Name = "Title",
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = (icon and UDim2.fromScale(0.259, 0.029) or UDim2.fromScale(0, 0.085)),
				Size = (icon and UDim2.fromScale(0.737, 0.914) or UDim2.fromScale(1, 0.795)),
				Font = utility.primary_font.standard,
				Text = tab_name,
				TextColor3 = current_theme.TextColor,
				TextScaled = true,
				TextWrapped = true,
				TextXAlignment = (icon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center),
				ZIndex = 5
			});
		})
		
		utility.tween_obj(content, {
			CanvasSize = UDim2.fromOffset(0, content.UIListLayout.AbsoluteContentSize.Y + 10)
		}, .2)
		
		theme_gui_objects[tab_button.Title] = "TextColor"
		theme_gui_objects[tab_button.bg] = "SchemeColor"
		
		if current_tab == nil then
			current_tab = tab_name
			utility.tween_obj(tab_button.bg, { BackgroundTransparency = 0 }, .2)
		end
		
		--tab_content
		local tab_page = create_instance("ScrollingFrame", {
			Name = tab_name,
			Parent = tab_content,
			Active = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			ScrollBarImageColor3 = current_theme.SchemeColor,
			ScrollBarThickness = 10,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.fromScale(0.979, 1.002),
			CanvasSize = UDim2.fromOffset(0, 0),
			BottomImage = "rbxassetid://8214604701",
			MidImage = "rbxassetid://8214611131",
			TopImage = "rbxassetid://8214610187"
		}, {
			create_instance("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder
			});
			
			create_instance("UIPadding", {
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 10)
			});
		})
		theme_gui_objects[tab_page] = "SchemeColor"
		
		tab_button_connections:Connect(tab_button.MouseButton1Click, function()
			if content:FindFirstChild(current_tab) then
				utility.tween_obj(content:FindFirstChild(current_tab).bg, { BackgroundTransparency = 1 }, .2)
			end
			current_tab = tab_page.Name
			
			utility.tween_obj(tab_button.bg, { BackgroundTransparency = 0 }, .2)
			
			tab_page_layout:JumpTo(tab_page)
		end)
		
		local list_layout = tab_page.UIListLayout
		local function update_canvas()
			utility.tween_obj(tab_page, { CanvasSize = UDim2.fromOffset(0, (list_layout.AbsoluteContentSize.Y + 25)) }, .2)
		end

		function tab:new_label(text)
			local label = {}
			
			local label_instance = create_instance("Frame", {
				Name = "Label",
				Parent = tab_page,
				BackgroundColor3 = current_theme.ElementColor,
				Size = UDim2.new(1, -15, 0, 40),
				LayoutOrder = (#tab_page:GetChildren()-1)
			}, {
				create_instance("UICorner", {
					CornerRadius = UDim.new(0.2, 0)
				}),
				
				create_instance("TextLabel", {
					Name = "Title",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 0.75),
					Font = utility.primary_font.standard,
					Text = text,
					TextColor3 = current_theme.TextColor,
					TextScaled = true,
					TextWrapped = true
				})
			})
			
			
			theme_gui_objects[label_instance] = "ElementColor"
			theme_gui_objects[label_instance.Title] = "TextColor"
			
			update_canvas()

			function label:update(new_text)
				if (closing) then return end
				if (new_text ~= label_instance.Title.Text) then
					label_instance.Title.Text = new_text
				end
			end

			return label
		end

		function tab:new_button(text, callback)
			local button = {}
			
			local button_instance = create_instance("Frame", {
				Name = "Button",
				Parent = tab_page,
				BackgroundColor3 = current_theme.ElementColor,
				Size = UDim2.new(1, -15, 0, 40),
				LayoutOrder = (#tab_page:GetChildren()-1)
			}, {
				create_instance("UICorner", {
					CornerRadius = UDim.new(0.2, 0)
				}),

				create_instance("TextLabel", {
					Name = "Title",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.4, 0.5),
					Size = UDim2.fromScale(0.75, 0.75),
					Font = utility.primary_font.standard,
					Text = text,
					TextColor3 = current_theme.TextColor,
					TextScaled = true,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 2
				}),
				
				create_instance("ImageLabel", {
					Name = "Icon",
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.913, 0.125),
					Size = UDim2.fromScale(0.07, 0.8),
					Image = "rbxassetid://9728118892",
					ImageColor3 = current_theme.TextColor,
					ZIndex = 2
				}),
				
				create_instance("TextButton", {
					Name = "button",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					ZIndex = 5,
					Text = ""
				})
			})
			
			theme_gui_objects[button_instance] = "ElementColor"
			theme_gui_objects[button_instance.Title] = "TextColor"
			theme_gui_objects[button_instance.Icon] = "TextColor"
			
			update_canvas()
			
			if callback then
				main_connections:Connect(button_instance.button.MouseButton1Click, function()
					utility.call_function(callback)
				end)
			end

			function button:update(new_text)
				if (closing) then return end
				if (new_text ~= button_instance.Title.Text) then
					button_instance.Title.Text = new_text
				end
			end

			return button
		end

		function tab:new_toggle(text, state, callback)
			local toggle = {}
			state = state or false
			
			local toggle_instance = create_instance("Frame", {
				Name = "Toggle",
				Parent = tab_page,
				BackgroundColor3 = current_theme.ElementColor,
				Size = UDim2.new(1, -15, 0, 40),
				LayoutOrder = (#tab_page:GetChildren()-1)
			},{
				create_instance("UICorner", {
					CornerRadius = UDim.new(0.2, 0)
				}),
				
				create_instance("TextLabel", {
					Name = "Title",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.4, 0.5),
					Size = UDim2.fromScale(0.75, 0.75),
					Font = utility.primary_font.standard,
					Text = text,
					TextColor3 = current_theme.TextColor,
					TextScaled = true,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left
				}),
				
				create_instance("Frame", {
					Name = "toggle",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = current_theme.Background,
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.880, 0.5),
					Size = UDim2.fromScale(0.212, 0.75),
					ZIndex = 2,
				},{
					create_instance("UICorner", {
						CornerRadius = UDim.new(0.15, 0)
					}),
					
					create_instance("Frame", {
						Name = "toggleui",
						BackgroundColor3 = (state and (current_theme == utility.preset_themes.darktheme and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(85, 255, 0)) or (current_theme == utility.preset_themes.darktheme and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(220, 20, 60))),
						BorderSizePixel = 0,
						Position = (state and UDim2.fromScale(0.5, 0) or UDim2.fromScale(0, 0)),
						Size = UDim2.fromScale(0.5, 1),
						ZIndex = 3,
					},{
						create_instance("UICorner", {
							CornerRadius = UDim.new(0.2, 0)
						})
					}),
					
					create_instance("TextButton", {
						Name = "button",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 5,
						Text = ""
					})
					
				})
			})
			
			theme_gui_objects[toggle_instance] = "ElementColor"
			theme_gui_objects[toggle_instance.Title] = "TextColor"
			theme_gui_objects[toggle_instance.toggle] = "Background"
			

			
			update_canvas()
			
			
			local current_state = state
			
			toggle_instance:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
				if (current_state) then 
					if (current_theme == utility.preset_themes.darktheme) then
						utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.fromScale(0.5, 0) }, .1)
					else
						utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(85, 255, 0), Position = UDim2.fromScale(0.5, 0) }, .1)
					end
				else 
					if (current_theme == utility.preset_themes.darktheme) then
						utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(0, 0, 0), Position = UDim2.fromScale(0, 0) }, .1)
					else
						utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(220, 20, 60), Position = UDim2.fromScale(0, 0) }, .1)
					end
				end
			end)
			
			if callback then
				main_connections:Connect(toggle_instance.toggle.button.MouseButton1Click, function() 
					current_state = not current_state
					if current_state then
						if (current_theme == utility.preset_themes.darktheme) then
							utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.fromScale(0.5, 0) }, .1)
						else
							utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(85, 255, 0), Position = UDim2.fromScale(0.5, 0) }, .1)
						end
					else
						if (current_theme == utility.preset_themes.darktheme) then
							utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(0, 0, 0), Position = UDim2.fromScale(0, 0) }, .1)
						else
							utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(220, 20, 60), Position = UDim2.fromScale(0, 0) }, .1)
						end
					end
					utility.call_function(callback, current_state)
				end)
			end
			

			function toggle:update(new_text, new_state)
				if (closing) then return end
				if (new_text and new_text ~= toggle_instance.Title.Text) then
					toggle_instance.Title.Text = new_text
				end
				
				if new_state ~= nil then
					if new_state then
						if (current_theme == utility.preset_themes.darktheme) then
							utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.fromScale(0.5, 0) }, .1)
						else
							utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(85, 255, 0), Position = UDim2.fromScale(0.5, 0) }, .1)
						end
					else
						if (current_theme == utility.preset_themes.darktheme) then
							utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(0, 0, 0), Position = UDim2.fromScale(0, 0) }, .1)
						else
							utility.tween_obj(toggle_instance.toggle.toggleui, { BackgroundColor3 = Color3.fromRGB(220, 20, 60), Position = UDim2.fromScale(0, 0) }, .1)
						end
					end
					current_state = new_state
					utility.call_function(callback, new_state)
				end
			end

			return toggle
		end

		function tab:new_slider(text, min, max, state, callback)
			local slider = {}
			local dragging = false
			local dragging_con
			local mouse_con
			
			local slider_instance = create_instance("Frame", {
				Name = "Slider",
				Parent = tab_page,
				BackgroundColor3 = current_theme.ElementColor,
				Size = UDim2.new(1, -15, 0, 60),
				LayoutOrder = (#tab_page:GetChildren()-1)
			}, {
				create_instance("UICorner",{
					CornerRadius = UDim.new(0.2, 0)
				}),
				
				create_instance("TextLabel", {
					Name = "Title",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.4, 0.335),
					Size = UDim2.fromScale(0.75, 0.42),
					Font = utility.primary_font.standard,
					Text = text,
					TextColor3 = current_theme.TextColor,
					TextScaled = true,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left
				}),
				
				create_instance("Frame", {
					Name = "amount",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = current_theme.Background,
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.885, 0.335),
					Size = UDim2.fromScale(0.19, 0.42),
					ZIndex = 2,
				}, {
					create_instance("UICorner",{
						CornerRadius = UDim.new(0.2, 0)
					}),
					
					create_instance("TextBox",{
						Name = "Label",
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						ZIndex = 3,
						Font = utility.primary_font.standard,
						Text = tostring(state),
						TextColor3 = current_theme.TextColor,
						TextScaled = true,
						TextWrapped = true
					})
				}),
				
				create_instance("Frame", {
					Name = "slider",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = current_theme.Background,
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.5, 0.75),
					Size = UDim2.fromScale(0.955, 0.195),
					ZIndex = 2
				}, {
					create_instance("UICorner",{
						CornerRadius = UDim.new(1, 0)
					}),
					
					create_instance("TextButton", {
						Name = "button",
						BackgroundColor3 = current_theme.SchemeColor,
						Size = UDim2.new(math.clamp(((state - min)) / (max - min), 0.02, 1), 0, 1, 0),
						ZIndex = 5,
						AutoButtonColor = false,
						Font = Enum.Font.SourceSans,
						Text = "",
					}, {
						create_instance("UICorner",{
							CornerRadius = UDim.new(1, 0)
						})
					})
				})
			})
			
			theme_gui_objects[slider_instance] = "ElementColor"
			theme_gui_objects[slider_instance.Title] = "TextColor"
			theme_gui_objects[slider_instance.amount] = "Background"
			theme_gui_objects[slider_instance.amount.Label] = "TextColor"
			theme_gui_objects[slider_instance.slider] = "Background"
			theme_gui_objects[slider_instance.slider.button] = "SchemeColor"
			
			update_canvas()
			
			local value
			
			local function to_percentage(input)
				return math.clamp(((input - min)) / (max - min), 0, 1)
			end
			
			local init = false
			local function update_value(percent)
				percent = math.clamp(percent, 0, 1)
				local raw_value = math.floor(min + (max - min) * percent)
				
				if raw_value ~= value then
					value = raw_value
					if (callback and init) then
						utility.call_function(callback, value)
					end
					init = true
				end
				
				
				return value
			end
			
			slider_instance.amount.Label.Text = tostring(update_value(to_percentage(state)))
			main_connections:Connect(slider_instance.slider.button.MouseButton1Down, function() 
				if not dragging then
					mouse_con = mouse.Move:Connect(function()
						local percent = (mouse.X - slider_instance.slider.button.AbsolutePosition.X) / slider_instance.slider.AbsoluteSize.X
						
						slider_instance.amount.Label.Text = tostring(update_value(percent))
						utility.tween_obj(slider_instance.slider.button, { Size = UDim2.fromScale(math.clamp(percent, 0.02, 1), 1) }, 0.1)
					end)

					dragging_con = user_input_service.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = false

							dragging_con:Disconnect()
							mouse_con:Disconnect()
						end
					end)
				end


				dragging = true
			end)

			function slider:update(new_text, new_state)
				if (closing) then return end
				if (new_text and new_text ~= slider_instance.Title.Text) then
					slider_instance.Title.Text = new_text
				end
				
				if (new_state) then
					local percent = to_percentage(new_state)
					slider_instance.amount.Label.Text = tostring(update_value(percent))
					utility.tween_obj(slider_instance.slider.button, { Size = UDim2.fromScale(math.clamp(percent, 0.02, 1), 1) }, 0.05)
				end
			end
			
			local focused = false
			slider_instance.amount.Label.Focused:Connect(function()
				focused = true
			end)
			slider_instance.amount.Label.FocusLost:Connect(function()
				focused = false
				if (slider_instance.amount.Label.Text == "") then
					slider_instance.amount.Label.Text = tostring(value)
				elseif (tonumber(slider_instance.amount.Label.Text) < min) then
					slider_instance.amount.Label.Text = tostring(min)
					value = min
				elseif (tonumber(slider_instance.amount.Label.Text) > max) then
					slider_instance.amount.Label.Text = tostring(max)
					value = max
				end
			end)
			
			main_connections:Connect(slider_instance.amount.Label:GetPropertyChangedSignal("Text"), function()
				if focused then
					local new_text = slider_instance.amount.Label.Text
					if (new_text ~= "" and tonumber(new_text)) then
						new_text = tonumber(new_text)
						
						local percent = to_percentage(new_text)
						update_value(percent)
						utility.tween_obj(slider_instance.slider.button, { Size = UDim2.fromScale(math.clamp(percent, 0.02, 1), 1) }, 0.2)
					end
				end
			end)

			return slider
		end

		function tab:new_textbox(text, callback_type, callback)
			local textbox = {}
			local callback_type_ = callback_type
			
			local textbox_instance = create_instance("Frame", {
				Name = "TextBox",
				Parent = tab_page,
				BackgroundColor3 = current_theme.ElementColor,
				LayoutOrder = (#tab_page:GetChildren()-1),
				Size = UDim2.new(1, -15, 0, 40)
			}, {
				create_instance("UICorner",{
					CornerRadius = UDim.new(0.2, 0)
				}),
				
				create_instance("TextLabel", {
					Name = "Title",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1.000,
					Position = UDim2.fromScale(0.33, 0.5),
					Size = UDim2.fromScale(0.613, 0.75),
					Font = utility.primary_font.standard,
					Text = text,
					TextColor3 = current_theme.TextColor,
					TextScaled = true,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left
				}),
				
				create_instance("Frame", {
					Name = "txtbox",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = current_theme.Background,
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.895, 0.5),
					Size = UDim2.fromScale(0.183, 0.75),
					ZIndex = 2
				}, {
					create_instance("UICorner",{
						CornerRadius = UDim.new(0.2, 0)
					}),
					
					create_instance("TextBox",{
						Name = "box",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 3,
						Font = utility.primary_font.standard,
						PlaceholderText = "...",
						Text = "",
						TextColor3 = current_theme.TextColor,
						TextScaled = true,
						TextWrapped = true
					})
				})
			})
			
			theme_gui_objects[textbox_instance] = "ElementColor"
			theme_gui_objects[textbox_instance.Title] = "TextColor"
			theme_gui_objects[textbox_instance.txtbox] = "Background"
			theme_gui_objects[textbox_instance.txtbox.box] = "TextColor"
			
			update_canvas()
			
			local text_box: TextBox = textbox_instance.txtbox.box
			
			local focused = false
			main_connections:Connect(text_box.Focused, function()
				focused = true
				utility.tween_obj(textbox_instance.txtbox, { Position = UDim2.fromScale(0.82, 0.5), Size = UDim2.fromScale(0.33, 0.75) }, .2)
			end)
			
			main_connections:Connect(text_box.FocusLost, function()
				focused = false
				utility.tween_obj(textbox_instance.txtbox, { Position = UDim2.fromScale(0.895, 0.5), Size = UDim2.fromScale(0.18, 0.75) }, .2)
				if callback_type_ == 1 then
					utility.call_function(callback, text_box.Text)
				end
			end)
			
			main_connections:Connect(text_box:GetPropertyChangedSignal("Text"), function()
				if focused then
					if callback_type_ == 0 then
						utility.call_function(callback, text_box.Text)
					end
				end
			end)

			function textbox:update(text, new_callback_type)
				if (closing) then return end
				if (text and text ~= textbox_instance.Title.Text) then
					textbox_instance.Title.Text = text
				end
				
				if new_callback_type then
					callback_type_ = math.clamp(callback_type_, 0, 1)
				end
			end

			return textbox
		end

		function tab:new_keybind(text, key: Enum.KeyCode, call_type, callback)
			local keybind = {}
			local key_bind = utility.insert_key(key, call_type, callback)
			text = ("[" .. key.Name .. "]: " .. tostring(text))
			local label = tab:new_label(text)

			function keybind:update(new_text, new_key)
				if (new_text) then 
					text = new_text
					if (not new_key) then 
						label:update(("[" .. key.Name .. "]: " .. tostring(new_text)))
					end
				end
				
				if (new_key) then 
					key_bind:kill()
					key_bind = utility.insert_key(new_key, callback)
					label:update(("[" .. key.Name .. "]: " .. tostring(new_text)))
				end	
			end

			function keybind:disable()
				key_bind:disable()
			end

			function keybind:enable()
				key_bind:enable()
			end

			return keybind
		end

		function tab:new_dropdown(text, list, callback)
			local dropdown = {}
			local dropdown_buttons = {}
			local current_selected = "..."
			
			local dropdown_instance = create_instance("Frame", {
				Name = "Dropdown",
				Parent = tab_page,
				BackgroundColor3 = current_theme.ElementColor,
				LayoutOrder = (#tab_page:GetChildren() - 1),
				Size = UDim2.new(1, -15, 0, 40)
			}, {
				create_instance("UICorner",{
					CornerRadius = UDim.new(0, 8)
				}),
				
				create_instance("Frame", {
					Name = "top",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -15, 0, 40)
				},{
					create_instance("Frame", {
						Name = "txtbox",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = current_theme.Background,
						BorderSizePixel = 0,
						Position = UDim2.new(0.1, 0, 0.5, 0),
						Size = UDim2.new(0.18, 0, 0.75, 0),
						ZIndex = 2
					},{
						create_instance("UICorner",{
							CornerRadius = UDim.new(0.2, 0)
						}),
						
						create_instance("TextBox", {
							Name = "box",
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 1, 0),
							ZIndex = 3,
							Font = utility.primary_font.standard,
							PlaceholderText = "...",
							Text = "",
							TextColor3 = current_theme.TextColor,
							TextScaled = true,
							TextSize = 14.000,
							TextWrapped = true
						})
					}),
					
					create_instance("ImageLabel", {
						Name = "open",
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundTransparency = 1,
						Position = UDim2.new(0.97, 0, 0.5, 0),
						Size = UDim2.new(0.04, 0, 0.475, 0),
						ZIndex = 6,
						Image = "rbxassetid://10776061253",
						ImageColor3 = current_theme.SchemeColor
					}),
					
					create_instance("TextButton", {
						Name = "button",
						BackgroundTransparency = 1,
						Position = UDim2.new(0.942, 0, 0, 0),
						Size = UDim2.new(0.09, 0, 1, 0),
						Font = utility.primary_font.standard,
						Text = "",
						TextColor3 = Color3.fromRGB(0, 0, 0),
						TextSize = 14
					})
				}),
				
				create_instance("Frame",{
					Name = "content",
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = current_theme.Background,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					Position = UDim2.new(0.5, 0, 0.283339798, 0),
					Size = UDim2.new(1, -15, 0, 0),
				}, {
					create_instance("UICorner",{
						CornerRadius = UDim.new(0, 5)
					}),
					
					create_instance("ScrollingFrame",{
						Name = "content",
						Active = true,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 1, 0),
						CanvasSize = UDim2.fromOffset(0, 0);
						ScrollBarThickness = 3,
						ScrollBarImageColor3 = current_theme.SchemeColor,
						TopImage = "rbxassetid://8214610187",
						MidImage = "rbxassetid://8214611131",
						BottomImage = "rbxassetid://8214604701",
					},{
						create_instance("UIListLayout", {
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 5)
						}),
						
						create_instance("UIPadding", {
							PaddingTop = UDim.new(0, 5)
						}),
					})
				})
			})
			
			theme_gui_objects[dropdown_instance] = "ElementColor"
			theme_gui_objects[dropdown_instance.top.txtbox] = "Background"
			theme_gui_objects[dropdown_instance.top.txtbox.box] = "TextColor"
			theme_gui_objects[dropdown_instance.top.open] = "SchemeColor"
			theme_gui_objects[dropdown_instance.content] = "Background"
			theme_gui_objects[dropdown_instance.content.content] = "SchemeColor"

			local function update_dropdown_canvas(scroll)
				scroll = (type(scroll) == "boolean" and scroll or false)
				
				if (scroll) then 
					utility.tween_obj(dropdown_instance.content.content, { 
						CanvasSize = UDim2.fromOffset(0, (dropdown_instance.content.content.UIListLayout.AbsoluteContentSize.Y + 10)), 
						CanvasPosition = Vector2.new(0, (dropdown_instance.content.content.UIListLayout.AbsoluteContentSize.Y + 10)) 
					}, .2)
					
					return
				end
				
				utility.tween_obj(dropdown_instance.content.content, { 
					CanvasSize = UDim2.fromOffset(0, (dropdown_instance.content.content.UIListLayout.AbsoluteContentSize.Y + 10)),
					CanvasPosition = Vector2.new(0, 0)
				}, .2)
			end

			local function call_func(name) -- this is so stupid
				if (callback == nil) then return end
				utility.call_function(callback, name)
			end
			
			local dd_closed, dd_debounce = true, true
			main_connections:Connect(dropdown_instance.top.button.MouseButton1Click, function()
				if (not dd_debounce) then return end
				if (dd_closed) then 
					dd_closed, dd_debounce = false, false
					
					utility.tween_obj(dropdown_instance.top.open, { Rotation = 180 }, .3)
					
					utility.tween_obj(dropdown_instance, {
						Size = UDim2.new(1, -15, 0, 160)
					}, .4); task.wait(.4)
					
					utility.tween_obj(dropdown_instance.content, {
						Size = UDim2.new(1, -15, 0, 110)
					}, .4); task.wait(.4)
					
					dd_debounce = true
				else
					dd_closed, dd_debounce = true, false
					
					utility.tween_obj(dropdown_instance.top.open, { Rotation = 0 }, .3)
					
					utility.tween_obj(dropdown_instance.content, {
						Size = UDim2.new(1, -15, 0, 0)
					}, .4); task.wait(.4)

					utility.tween_obj(dropdown_instance, {
						Size = UDim2.new(1, -15, 0, 40)
					}, .4); task.wait(.4)
					
					dd_debounce = true
				end
			end)
			

			main_connections:Connect(dropdown_instance.top.txtbox.box.Focused, function()
				dropdown_instance.top.txtbox.box.PlaceholderText = ""
				utility.tween_obj(dropdown_instance.top.txtbox, { Size = UDim2.fromScale(0.33, 0.75), Position = UDim2.fromScale(0.175, .5) }, .3)
			end)

			main_connections:Connect(dropdown_instance.top.txtbox.box.FocusLost, function()
				dropdown_instance.top.txtbox.box.PlaceholderText = current_selected
				utility.tween_obj(dropdown_instance.top.txtbox, { Size = UDim2.fromScale(0.18, 0.75), Position = UDim2.fromScale(0.1, .5) }, .3)
			end)
			
			local just_edited = false
			main_connections:Connect(dropdown_instance.top.txtbox.box:GetPropertyChangedSignal("Text"), function()
				local text = dropdown_instance.top.txtbox.box.Text
				if (text ~= "") then 
					for i,v in next, dropdown_instance.content.content:GetChildren() do
						if v:IsA("Frame") then 
							if (string.find(v.Name, text)) then 
								v.Visible = true
							else
								v.Visible = false
							end
						end
					end
					update_dropdown_canvas(false)
				else
					just_edited = true
					for i,v in next, dropdown_instance.content.content:GetChildren() do
						if v:IsA("Frame") then 
							v.Visible = true
						end
					end
				end
			end)

			main_connections:Connect(dropdown_instance:GetPropertyChangedSignal("Size"), update_canvas)
			main_connections:Connect(dropdown_instance.content.content.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				if (just_edited) then 
					update_dropdown_canvas(false)
					just_edited = false
				else
					update_dropdown_canvas(true)
				end
			end)

			function dropdown:add(item_text)
				local bttn = dropdown_instance.content.content:FindFirstChild(item_text)
				utility.assert(bttn == nil, "dropdown item already exist!", 2)
				if (bttn == nil) then
					local new_bttn = create_instance("Frame", {
						Name = item_text,
						Parent = dropdown_instance.content.content,
						BackgroundColor3 = current_theme.ElementColor,
						LayoutOrder = (#dropdown_instance.content.content:GetChildren() - 1),
						Size = UDim2.new(1, -15, 0, 40),
					}, {
						create_instance("UICorner", {
							CornerRadius = UDim.new(0.2, 0)
						}),

						create_instance("TextLabel", {
							Name = "title",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.new(0.511, 0, 0.5, 0),
							Size = UDim2.new(0.971, 0, 0.75, 0),
							Font = utility.primary_font.standard,
							Text = item_text,
							TextColor3 = current_theme.TextColor,
							TextScaled = true,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),

						create_instance("TextButton", {
							Name = "button",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 1, 0),
							ZIndex = 5,
							Text = "",
						})
					})

					if (callback ~= nil) then 
						dropdown_buttons[new_bttn] = new_bttn.button.MouseButton1Click:Connect(function()
							call_func(item_text)
							dropdown_instance.top.txtbox.box.PlaceholderText = item_text
							current_selected = item_text
						end)
					else
						dropdown_buttons[new_bttn] = true
					end


					theme_gui_objects[new_bttn] = "ElementColor"
					theme_gui_objects[new_bttn.title] = "TextColor"
				end
			end

			function dropdown:remove(item_text)
				local bttn = dropdown_instance.content.content:FindFirstChild(item_text)
				
				if (bttn) then 
					theme_gui_objects[bttn] = nil
					theme_gui_objects[bttn.title] = nil
					
					if (dropdown_buttons[bttn] and dropdown_buttons[bttn] ~= true) then 
						dropdown_buttons[bttn]:Disconnect() 
					end
					dropdown_buttons[bttn] = nil
					
					bttn:Destroy()
				end
			end
			
			function dropdown:edit(old_text, new_text)
				utility.assert(old_text, "argument #1 is nil!", 2)
				utility.assert(new_text, "argument #2 is nil!", 2)
				
				if (old_text and new_text) then
					if (dropdown_instance.content.content:FindFirstChild(new_text)) then utility.assert(nil, "unable to edit since dropdown item already exist!", 2) return end
					local bttn = dropdown_instance.content.content:FindFirstChild(old_text)
					if (bttn:IsA("Frame")) then 
						bttn.Name = new_text
						bttn.title.Text = new_text
					end
				end
			end
			
			function dropdown:clear()
				for i, v in next, dropdown_buttons do
					if (theme_gui_objects[i.title]) then theme_gui_objects[i.title] = nil end
					theme_gui_objects[i] = nil
					
					if (v ~= true and v ~= nil) then 
						v:Disconnect() -- v is the connection 
					end
					
					dropdown_buttons[i] = nil
					i:Destroy() -- i is the instance
				end
			end
			
			function dropdown:update(txt)
				local bttn = dropdown_instance.content.content:FindFirstChild(tostring(txt))
				if (txt and bttn) then 
					if (bttn:IsA("Frame")) then 
						current_selected = txt
						call_func(txt)
					end
				end
			end
			

			for i, text in next, list do 
				local new_bttn = create_instance("Frame", {
					Name = text,
					Parent = dropdown_instance.content.content,
					BackgroundColor3 = current_theme.ElementColor,
					LayoutOrder = (#dropdown_instance.content.content:GetChildren() - 1),
					Size = UDim2.new(1, -15, 0, 40),
				}, {
					create_instance("UICorner", {
						CornerRadius = UDim.new(0.2, 0)
					}),

					create_instance("TextLabel", {
						Name = "title",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Position = UDim2.new(0.511, 0, 0.5, 0),
						Size = UDim2.new(0.971, 0, 0.75, 0),
						Font = utility.primary_font.standard,
						Text = text,
						TextColor3 = current_theme.TextColor,
						TextScaled = true,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					create_instance("TextButton", {
						Name = "button",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 5,
						Text = "",
					})
				})

				if (callback ~= nil) then 
					dropdown_buttons[new_bttn] = new_bttn.button.MouseButton1Click:Connect(function()
						call_func(text)
						dropdown_instance.top.txtbox.box.PlaceholderText = text
						current_selected = text
					end)
				else
					dropdown_buttons[new_bttn] = true
				end


				theme_gui_objects[new_bttn] = "ElementColor"
				theme_gui_objects[new_bttn.title] = "TextColor"
			end
			
			return dropdown
		end
		
		function tab:update(text, icon)
			if (closing) then return end
			if (text and tab_page.Name ~= text) then
				if content:FindFirstChild(text) then
					utility.assert(false, "page already exist!", 2)
					return false
				end
				
				tab_button.Name = text
				tab_button.Title.Text = text
				tab_page.Name = text
			end
			
			if (icon) then
				icon = tonumber(icon)
				if (icon and icon > 0) then
					icon = "rbxassetid://" .. tostring(icon)
					
					if (tab_button.Icon.Image == "" or tab_button.Icon.Image == nil) then
						utility.tween_obj(tab_button.Title, {
							Size = UDim2.fromScale(0.737, 0.914),
							Position = UDim2.fromScale(0.259, 0.029),
							TextTransparency = 1
						}, .2)
						
						task.wait(.25)
						
						tab_button.TextXAlignment = Enum.TextXAlignment.Left
						tab_button.Icon.ImageTransparency = 1
						tab_button.Icon.Visible = true
						
						utility.tween_obj(tab_button.Title, {
							TextTransparency = 0
						}, .2)
						utility.tween_obj(tab_button.Icon, {
							ImageTransparency = 0
						}, .2)
					end
					
					tab_button.Icon.Image = icon
				else
					utility.tween_obj(tab_button.Icon, {
						ImageTransparency = 1
					}, .2)
					utility.tween_obj(tab_button.Title, {
						TextTransparency = 1
					}, .2)
					
					task.wait(.25)
					
					tab_button.TextXAlignment = Enum.TextXAlignment.Center
					tab_button.Icon.Visible = false
					tab_button.Icon.ImageTransparency = 0
					tab_button.Icon.Image = ""
					
					utility.tween_obj(tab_button.Title, {
						Size = UDim2.fromScale(1, 0.795),
						Position = UDim2.fromScale(0, 0.085),
						TextTransparency = 0
					}, .2)
				end
			end
			
			return true
		end

		return tab
	end
	
	function window:update(text)
		if (text and frame_window.Name ~= text) then
			utility.tween_obj(title, {
				TextTransparency = 1
			}, .1)
			
			task.wait(.15)
			title.Text = tostring(text)
			
			utility.tween_obj(title, {
				TextTransparency = 0
			}, .1)
		end
	end
	
	function window:toggle_gui()
		frame_window.Visible = not frame_window.Visible
	end
	
	local noti_count = { left = 0, right = 0 }
	function window:send_notifacation(title, infomation, time_limit, side, callback)
		if (closing) then return end
		side = (string.lower(tostring(side)) == "left" and 0 or string.lower(tostring(side)) == "right" and 1 or side)
		side = (tonumber(side) and math.floor(tonumber(side)) or nil)
		time_limit = tonumber(time_limit)
		callback = (type(callback) == "function" and callback or nil)

		time_limit = time_limit or 3
		side = side or 1
		side = math.clamp(side, 0, 1)
		
		local noti = gui:FindFirstChild("notis")
		if noti == nil then
			noti = create_instance("Frame", {
				Name = "notis",
				Parent = gui,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1)
			}, {
				create_instance("Frame", {
					Name = "Left",
					BackgroundColor3 = Color3.fromRGB(85, 255, 255),
					BackgroundTransparency = 1.000,
					Size = UDim2.fromScale(0.2, 0.995)
				}, {
					create_instance("UIListLayout", {
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Bottom,
						Padding = UDim.new(0, 5)
					})
				}),
				
				create_instance("Frame", {
					Name = "Right",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.new(0.8, 0),
					Size = UDim2.fromScale(0.2, 0.995)
				}, {
					create_instance("UIListLayout", {
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Bottom,
						Padding = UDim.new(0, 5)
					})
				})
			})
		end

		if (title and infomation) then
			if side == 0 then
				noti_count.left = noti_count.left + 1
			elseif side == 1 then
				noti_count.right = noti_count.right + 1
			end
			
			local parent = (side == 0 and noti.Left or side == 1 and noti.Right)
			local layout_index = (side == 0 and noti_count.left or side == 1 and noti_count.right)
				
			local notifacation = create_instance("Frame", {
				Name = "notifacation",
				Parent = parent,
				BackgroundColor3 = current_theme.Background,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.019, 0.925),
				Size = UDim2.fromScale(0.960, 0),
				ZIndex = 999,
				LayoutOrder = noti_count,
				ClipsDescendants = true
			}, {
				create_instance("UICorner", {
					CornerRadius = UDim.new(0.1, 0)
				}),
				
				create_instance("TextLabel", {
					Name = "title",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.019, 0),
					Size = UDim2.fromScale(0.979, 0.350),
					ZIndex = 1000,
					Font = utility.primary_font.black,
					Text = title,
					TextColor3 = current_theme.TextColor,
					TextScaled = true,
					TextWrapped = true,
					TextXAlignment = (side == 0 and Enum.TextXAlignment.Left or side == 1 and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left),
					TextTransparency = 1
				}),
				
				create_instance("TextLabel", {
					Name = "infomation",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.0186, 0.325),
					Size = UDim2.fromScale(0.979, 0.675),
					ZIndex = 1000,
					Font = utility.primary_font.light,
					Text = infomation,
					TextColor3 = current_theme.TextColor,
					TextScaled = true,
					TextWrapped = true,
					TextXAlignment = (side == 0 and Enum.TextXAlignment.Left or side == 1 and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left),
					TextTransparency = 1
				}),
				
				create_instance("TextButton", {
					Name = "close",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 1001,
					Text = ""
				})
			})
			
			theme_gui_objects[notifacation] = "Background"
			theme_gui_objects[notifacation.title] = "TextColor"
			theme_gui_objects[notifacation.infomation] = "TextColor"
			
			
			coroutine.wrap(function()
				utility.tween_obj(notifacation, {
					Size = UDim2.fromScale(0.960, 0.074)
				}, .5)

				task.wait(.5)

				utility.tween_obj(notifacation.infomation, {
					TextTransparency = 0
				}, .2)
				utility.tween_obj(notifacation.title, {
					TextTransparency = 0
				}, .2)
			end)()
			
			
			local still_call = true
			local connection
			
			connection = notifacation.close.MouseButton1Click:Connect(function()
				still_call = false
				connection:Disconnect()
				
				task.wait(.2)
				
				coroutine.wrap(function()
					utility.tween_obj(notifacation.infomation, {
						TextTransparency = 1
					}, .3)
					utility.tween_obj(notifacation.title, {
						TextTransparency = 1
					}, .3)

					task.wait(.2)
					
					utility.tween_obj(notifacation, {
						Size = UDim2.fromScale(0.960, 0)
					}, .5)
					
					task.wait(.5)
					
					theme_gui_objects[notifacation] = nil
					theme_gui_objects[notifacation.title] = nil
					theme_gui_objects[notifacation.infomation] = nil
					
					notifacation:Destroy()
				end)()
				
				if callback then
					utility.call_function(callback)
				end
			end)
			
			if time_limit > 0 then
				coroutine.wrap(function()
					task.wait(time_limit)
					
					if still_call then
						connection:Disconnect()
						
						utility.tween_obj(notifacation.infomation, {
							TextTransparency = 1
						}, .3)
						utility.tween_obj(notifacation.title, {
							TextTransparency = 1
						}, .3)

						task.wait(.2)

						utility.tween_obj(notifacation, {
							Size = UDim2.fromScale(0.960, 0)
						}, .5)

						task.wait(.5)
						
						theme_gui_objects[notifacation] = nil
						theme_gui_objects[notifacation.title] = nil
						theme_gui_objects[notifacation.infomation] = nil

						notifacation:Destroy()
					end
				end)()
			end
		end
	end
	
	function window:change_theme(theme_list) -- this is eww lol
		if (closing) then return end
		theme_list = theme_list or utility.preset_themes.darktheme
		theme_list = (type(theme_list) == "string" and string.lower(theme_list) or theme_list)
		if (type(theme_list) == "string" and utility.preset_themes[theme_list]) then
			current_theme = utility.preset_themes[theme_list]
			
			for instance, color_type in pairs(theme_gui_objects) do
				if (string.lower(color_type):find("scheme")) then
					if string.lower(instance.ClassName):find("image") then
						utility.tween_obj(instance, { ImageColor3 = current_theme.SchemeColor }, .2)
						continue
					elseif instance:IsA("ScrollingFrame") then
						utility.tween_obj(instance, { ScrollBarImageColor3 = current_theme.SchemeColor }, .2)
						continue
					end

					utility.tween_obj(instance, { BackgroundColor3 = current_theme.SchemeColor }, .2)
				elseif (string.lower(color_type):find("background")) then
					if string.lower(instance.ClassName):find("image") then
						utility.tween_obj(instance, { ImageColor3 = current_theme.Background }, .2)
						continue
					elseif instance:IsA("ScrollingFrame") then
						utility.tween_obj(instance, { ScrollBarImageColor3 = current_theme.Background }, .2)
						continue
					end

					utility.tween_obj(instance, { BackgroundColor3 = current_theme.Background }, .2)
				elseif (string.lower(color_type):find("header")) then
					if string.lower(instance.ClassName):find("image") then
						utility.tween_obj(instance, { ImageColor3 = current_theme.Header }, .2)
						continue
					elseif instance:IsA("ScrollingFrame") then
						utility.tween_obj(instance, { ScrollBarImageColor3 = current_theme.Header }, .2)
						continue
					end

					utility.tween_obj(instance, { BackgroundColor3 = current_theme.Header }, .2)
				elseif (string.lower(color_type):find("text")) then
					if string.lower(instance.ClassName):find("text") then
						utility.tween_obj(instance, { TextColor3 = current_theme.TextColor }, .2)
						if string.lower(instance.ClassName):find("textbox") then utility.tween_obj(instance, { PlaceholderColor3 = Color3.fromRGB(((current_theme.TextColor.R * 255) * 0.8), ((current_theme.TextColor.G * 255) * 0.8), ((current_theme.TextColor.B * 255) * 0.8)) }, .2) end
					elseif string.lower(instance.ClassName):find("image") then
						utility.tween_obj(instance, { ImageColor3 = current_theme.TextColor }, .2)
					elseif instance:IsA("ScrollingFrame") then
						utility.tween_obj(instance, { ScrollBarImageColor3 = current_theme.TextColor }, .2)
						continue
					end
				elseif (string.lower(color_type):find("element")) then
					if string.lower(instance.ClassName):find("image") then
						utility.tween_obj(instance, { ImageColor3 = current_theme.ElementColor }, .2)
						continue
					elseif instance:IsA("ScrollingFrame") then
						utility.tween_obj(instance, { ScrollBarImageColor3 = current_theme.ElementColor }, .2)
						continue
					end

					utility.tween_obj(instance, { BackgroundColor3 = current_theme.ElementColor }, .2)
				end
			end
		elseif type(theme_list) == "table" then
			for color_type, color in pairs(theme_list) do 
				if (string.lower(color_type):find("scheme") and typeof(color) == "Color3") then
					current_theme.SchemeColor = color
				elseif (string.lower(color_type):find("background") and typeof(color) == "Color3") then
					current_theme.Background = color
				elseif (string.lower(color_type):find("header") and typeof(color) == "Color3") then
					current_theme.Header = color
				elseif (string.lower(color_type):find("text") and typeof(color) == "Color3") then
					current_theme.TextColor = color
				elseif (string.lower(color_type):find("element") and typeof(color) == "Color3") then
					current_theme.element = color
				end
			end
			
			for instance, color_type in pairs(theme_gui_objects) do
				if (string.lower(color_type):find("scheme")) then
					if string.lower(instance.ClassName):find("image") then
						utility.tween_obj(instance, { ImageColor3 = current_theme.SchemeColor }, .2)
						continue
					elseif instance:IsA("ScrollingFrame") then
						utility.tween_obj(instance, { ScrollBarImageColor3 = current_theme.SchemeColor }, .2)
						continue
					end
					
					utility.tween_obj(instance, { BackgroundColor3 = current_theme.SchemeColor }, .2)
				elseif (string.lower(color_type):find("background")) then
					if string.lower(instance.ClassName):find("image") then
						utility.tween_obj(instance, { ImageColor3 = current_theme.Background }, .2)
						continue
					elseif instance:IsA("ScrollingFrame") then
						utility.tween_obj(instance, { ScrollBarImageColor3 = current_theme.Background }, .2)
						continue
					end
					
					utility.tween_obj(instance, { BackgroundColor3 = current_theme.Background }, .2)
				elseif (string.lower(color_type):find("header")) then
					if string.lower(instance.ClassName):find("image") then
						utility.tween_obj(instance, { ImageColor3 = current_theme.Header }, .2)
						continue
					elseif instance:IsA("ScrollingFrame") then
						utility.tween_obj(instance, { ScrollBarImageColor3 = current_theme.Header }, .2)
						continue
					end
					
					utility.tween_obj(instance, { BackgroundColor3 = current_theme.Header }, .2)
				elseif (string.lower(color_type):find("text")) then
					if string.lower(instance.ClassName):find("text") then
						utility.tween_obj(instance, { TextColor3 = current_theme.TextColor }, .2)
						if string.lower(instance.ClassName):find("textbox") then utility.tween_obj(instance, { PlaceholderColor3 = Color3.fromRGB(((current_theme.TextColor.R * 255) * 0.8), ((current_theme.TextColor.G * 255) * 0.8), ((current_theme.TextColor.B * 255) * 0.8)) }, .2) end
					elseif string.lower(instance.ClassName):find("image") then
						utility.tween_obj(instance, { ImageColor3 = current_theme.TextColor }, .2)
					elseif instance:IsA("ScrollingFrame") then
						utility.tween_obj(instance, { ScrollBarImageColor3 = current_theme.TextColor }, .2)
						continue
					end
				elseif (string.lower(color_type):find("element")) then
					if string.lower(instance.ClassName):find("image") then
						utility.tween_obj(instance, { ImageColor3 = current_theme.ElementColor }, .2)
						continue
					elseif instance:IsA("ScrollingFrame") then
						utility.tween_obj(instance, { ScrollBarImageColor3 = current_theme.ElementColor }, .2)
						continue
					end
					
					utility.tween_obj(instance, { BackgroundColor3 = current_theme.ElementColor }, .2)
				end
			end
		end
	end
	
	function window:close()
		tab_button_connections:Dispose() -- disconnects all the connections
		main_connections:Dispose() -- disconnects all the connections
		
		closing = true		
		utility.tween_obj(frame_window.top.title, { TextTransparency = 1 }, .3) task.wait(.3)
		utility.tween_obj(frame_window.tabs.content, { ScrollBarImageTransparency = 1 }, .3) task.wait(.3)
		
		for i,v in next, closing_callbacks do 
			local s, e = pcall(v)
			if not s then 
				warn("[CLOSING CALLBACK ERROR]:", e)
			end
		end
		
		utility.tween_obj(frame_window, { Size = UDim2.new(frame_window.Size.X.Scale, frame_window.Size.X.Offset, 0, 0) }, .5) task.wait(.5)
		frame_window:Destroy()
		
		while task.wait() do -- waits til all notifacations are gone
			local des = gui:FindFirstChild("notis")
			if (des) then 
				des = des:GetDescendants()
				if (#des <= 4) then 
					gui:Destroy()
					break
				end
			else break end
		end
	end

	window.closing = setmetatable({}, {
		__index = function(self, idx)
			idx = string.lower(tostring(idx))

			if idx == "connect" then
				return function(t, callback) 
					table.insert(closing_callbacks, callback);

					local dis = function()
						local index = table.find(closing_callbacks, callback)
						table.remove(closing_callbacks, index)
					end

					return { Disconnect = dis }
				end
			end
		end,
		__metatable = "This metatable is locked!"
	})
	
	return window
end

return lib
