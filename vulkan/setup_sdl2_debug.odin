package vulkan_setup_sdl2_debug

import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:mem"
import "core:runtime"
import "core:slice"

import "vendor:sdl2"
import "vendor:vulkan"

main :: proc() {
	tracker : mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracker, context.allocator)
	defer mem.tracking_allocator_destroy(&tracker)
	context.allocator = mem.tracking_allocator(&tracker)
	defer if len(tracker.allocation_map) > 0 {
		fmt.eprintln()
		for _, v in tracker.allocation_map {
			fmt.eprintf("%v - leaked %v bytes\n", v.location, v.size)
		}
	}

	width, height : c.int = 1280, 720

	// initialise sdl2
	sdl2.Init(sdl2.INIT_VIDEO); defer sdl2.Quit()

	// create a vulkan window
	window := sdl2.CreateWindow("Odin SDL2 Vulkan", sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED, width, height, { .VULKAN }); defer sdl2.DestroyWindow(window)
	if window == nil {
		fmt.eprintln("sdl2 failed to create window")
		return
	}

	// load vulkan procedures before we start using them (only the ones we can by using nil)
	vulkan.load_proc_addresses(proc(p: rawptr, name: cstring) {
		fptr := cast(vulkan.ProcGetInstanceProcAddr) sdl2.Vulkan_GetVkGetInstanceProcAddr()
		(cast(^rawptr) p)^ = cast(rawptr) fptr(nil, name)
	})

	// lets make a handy little default debug thingy
	default_debug_utils_messenger := vulkan.DebugUtilsMessengerCreateInfoEXT{
		sType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
		messageSeverity = { .WARNING, .ERROR },
		messageType = { .VALIDATION, .PERFORMANCE },
		pfnUserCallback = proc "system" (
			messageSeverity: vulkan.DebugUtilsMessageSeverityFlagsEXT,
			messageTypes: vulkan.DebugUtilsMessageTypeFlagsEXT,
			pCallbackData: ^vulkan.DebugUtilsMessengerCallbackDataEXT,
			pUserData: rawptr,
		) -> b32 {
			context = runtime.default_context()
			fmt.eprintln("DebugUtilsMessenger:", pCallbackData.pMessage)
			return false
		},
	}

	// now make the instance
	instance : vulkan.Instance; defer vulkan.DestroyInstance(instance, nil)
	{
		// we specify a list of required extensions and layers
		required_extensions : [dynamic]cstring; defer delete(required_extensions)
		required_layers : [dynamic]cstring; defer delete(required_layers)

		// sdl has some required extensions
		{
			extension_count : c.uint
			sdl2.Vulkan_GetInstanceExtensions(window, &extension_count, nil)
			resize(&required_extensions, int(extension_count))
			sdl2.Vulkan_GetInstanceExtensions(window, &extension_count, raw_data(required_extensions))
		}


		// we can add a couple of debug extensions and layers
		when ODIN_DEBUG {
			append(&required_extensions, vulkan.EXT_DEBUG_REPORT_EXTENSION_NAME, vulkan.EXT_DEBUG_UTILS_EXTENSION_NAME)
			append(&required_layers, "VK_LAYER_KHRONOS_validation")
		}

		// let's just check the required extensions and layers are supported
		{
			// the full list of supported extensions
			supported_extensions := [dynamic]vulkan.ExtensionProperties{}; defer delete(supported_extensions)
			{
				extension_count : u32
				vulkan.EnumerateInstanceExtensionProperties(nil, &extension_count, nil)
				resize(&supported_extensions, int(extension_count))
				vulkan.EnumerateInstanceExtensionProperties(nil, &extension_count, raw_data(supported_extensions))
			}

			// the full list of supported layers
			supported_layers := [dynamic]vulkan.LayerProperties{}; defer delete(supported_layers)
			{
				layer_count : u32
				vulkan.EnumerateInstanceLayerProperties(&layer_count, nil)
				resize(&supported_layers, int(layer_count))
				vulkan.EnumerateInstanceLayerProperties(&layer_count, raw_data(supported_layers))
			}

			for required in required_extensions {
				contains := false
				for supported in &supported_extensions {
					name := transmute(cstring) &supported.extensionName
					if name == required {
						contains = true
						break
					}
				}
				if !contains {
					fmt.eprintln("extension", required, "is not in extensions list")
					return
				}
			}

			for required in required_layers {
				contains := false
				for supported in &supported_layers {
					name := transmute(cstring) &supported.layerName
					if name == required {
						contains = true
						break
					}
				}
				if !contains {
					fmt.eprintln("layer", required, "is not in layers list")
					return
				}
			}
		}

		// this is the structure to create the instance
		instance_info := vulkan.InstanceCreateInfo {
			sType = .INSTANCE_CREATE_INFO,
			enabledExtensionCount = u32(len(required_extensions)),
			ppEnabledExtensionNames = raw_data(required_extensions),
			enabledLayerCount = u32(len(required_layers)),
			ppEnabledLayerNames = raw_data(required_layers),
		}

		// we can also add a debug utils messenger extension
		when ODIN_DEBUG {
			instance_info.pNext = &default_debug_utils_messenger
		}

		if vulkan.CreateInstance(&instance_info, nil, &instance) != .SUCCESS {
			fmt.eprintln("failed to create vulkan instance")
			return
		}
	}

	// we can load the rest of the functions (we pass the instance using context.user_data)
	context.user_data = instance
	vulkan.load_proc_addresses(proc(p: rawptr, name: cstring) {
		fptr := cast(vulkan.ProcGetInstanceProcAddr) sdl2.Vulkan_GetVkGetInstanceProcAddr()
		inst := context.user_data.(vulkan.Instance)
		(cast(^rawptr) p)^ = cast(rawptr) fptr(inst, name)
	})

	// set up more debug stuff
	debug_utils_messenger : vulkan.DebugUtilsMessengerEXT; defer vulkan.DestroyDebugUtilsMessengerEXT(instance, debug_utils_messenger, nil)
	debug_report_callback : vulkan.DebugReportCallbackEXT; defer vulkan.DestroyDebugReportCallbackEXT(instance, debug_report_callback, nil)
	{
		debug_utils_messenger_info := default_debug_utils_messenger
		vulkan.CreateDebugUtilsMessengerEXT(instance, &debug_utils_messenger_info, nil, &debug_utils_messenger)

		debug_report_info := vulkan.DebugReportCallbackCreateInfoEXT{
			sType = .DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT,
			flags = { .ERROR, .PERFORMANCE_WARNING, .WARNING },
			pfnCallback = proc "system" (
				flags: vulkan.DebugReportFlagsEXT,
				objectType: vulkan.DebugReportObjectTypeEXT,
				object: u64,
				location: int,
				messageCode: i32,
				pLayerPrefix: cstring,
				pMessage: cstring,
				pUserData: rawptr,
			) -> b32 {
				context = runtime.default_context()
				fmt.eprintln("DebugReportCallback:", pMessage)
				return false
			},
		}
		vulkan.CreateDebugReportCallbackEXT(instance, &debug_report_info, nil, &debug_report_callback)
	}

	// this is the surface we can render to
	surface : vulkan.SurfaceKHR; defer vulkan.DestroySurfaceKHR(instance, surface, nil)
	if !sdl2.Vulkan_CreateSurface(window, instance, &surface) {
		fmt.eprintln("sdl couldn't create vulkan surface")
		return
	}

	// now to select a physical device (tada)
	physical_device      : vulkan.PhysicalDevice
	device_capabilities  : vulkan.SurfaceCapabilitiesKHR
	device_formats       : []vulkan.SurfaceFormatKHR; defer delete(device_formats)
	device_present_modes : []vulkan.PresentModeKHR; defer delete(device_present_modes)

	// it needs to support the extensions and queue families that we need
	queue_family_graphics_index := -1
	queue_family_present_index  := -1
	device_extensions           := []cstring{"VK_KHR_swapchain"}

	{
		// we need at least one vulkan device
		physical_device_count : u32
		vulkan.EnumeratePhysicalDevices(instance, &physical_device_count, nil)
		if physical_device_count == 0 {
			fmt.eprintln("no physical device with vulkan support detected")
			return
		}
		physical_devices := make([]vulkan.PhysicalDevice, physical_device_count); defer delete(physical_devices)
		vulkan.EnumeratePhysicalDevices(instance, &physical_device_count, raw_data(physical_devices))

		// work out which device is suitable
		for pd in &physical_devices {
			// check extension compatibility
			extension_count : u32
			vulkan.EnumerateDeviceExtensionProperties(pd, nil, &extension_count, nil)
			extensions := make([]vulkan.ExtensionProperties, int(extension_count)); defer delete(extensions)
			vulkan.EnumerateDeviceExtensionProperties(pd, nil, &extension_count, raw_data(extensions))

			requied_extensions := true
			for re in &device_extensions {
				contains := false
				for e in &extensions {
					name := transmute(cstring) &e.extensionName
					if re == name {
						contains = true
						break
					}
				}
				if !contains {
					requied_extensions = false
					break
				}
			}
			if !requied_extensions {
				continue
			}

			// device capabilities
			capabilities : vulkan.SurfaceCapabilitiesKHR
			vulkan.GetPhysicalDeviceSurfaceCapabilitiesKHR(pd, surface, &capabilities)

			// supported formats
			format_count : u32
			vulkan.GetPhysicalDeviceSurfaceFormatsKHR(pd, surface, &format_count, nil)
			if format_count == 0 {
				continue
			}
			formats := make([]vulkan.SurfaceFormatKHR, int(format_count)); defer delete(formats)
			vulkan.GetPhysicalDeviceSurfaceFormatsKHR(pd, surface, &format_count, raw_data(formats))

			// supported present modes
			present_mode_count : u32
			vulkan.GetPhysicalDeviceSurfacePresentModesKHR(pd, surface, &present_mode_count, nil)
			if present_mode_count == 0 {
				continue
			}
			present_modes := make([]vulkan.PresentModeKHR, int(present_mode_count)); defer delete(present_modes)
			vulkan.GetPhysicalDeviceSurfacePresentModesKHR(pd, surface, &present_mode_count, raw_data(present_modes))

			// check the device queue families
			queue_family_count : u32
			vulkan.GetPhysicalDeviceQueueFamilyProperties(pd, &queue_family_count, nil)
			queue_families := make([]vulkan.QueueFamilyProperties, int(queue_family_count)); defer delete(queue_families)
			vulkan.GetPhysicalDeviceQueueFamilyProperties(pd, &queue_family_count, raw_data(queue_families))

			graphics_index := -1
			present_index := -1
			for qf, i in &queue_families {
				if graphics_index == -1 && .GRAPHICS in qf.queueFlags {
					graphics_index = i
				}

				present_support : b32
				vulkan.GetPhysicalDeviceSurfaceSupportKHR(pd, u32(i), surface, &present_support)
				if present_index == -1 && present_support {
					present_index = i
				}

				if graphics_index != -1 && present_index != -1 {
					break
				}
			}

			// this will only be true with a suitable device
			if graphics_index != -1 && present_index != -1 {
				physical_device = pd
				device_capabilities = capabilities
				device_formats = slice.clone(formats)
				device_present_modes = slice.clone(present_modes)
				queue_family_graphics_index = graphics_index
				queue_family_present_index = present_index
				break
			}
		}

		if physical_device == nil {
			fmt.eprintln("suitable device not found")
			return
		}
	}

	// we can now make a logical device for our queues (and the queues themselves)
	device         : vulkan.Device; defer vulkan.DestroyDevice(device, nil)
	graphics_queue : vulkan.Queue
	present_queue  : vulkan.Queue
	{
		// this is just to avoid creating duplicates
		queue_families : map[int]int; defer delete(queue_families)
		queue_families[queue_family_graphics_index] += 1
		queue_families[queue_family_present_index] += 1

		// our queue priorities (this might be used incorrectly for queue_create_infos)
		queue_priorities := make([]f32, len(queue_families)); defer delete(queue_priorities)
		for qfc in 0 ..< len(queue_families) {
			queue_families[qfc] = 1.0
		}

		queue_create_infos : [dynamic]vulkan.DeviceQueueCreateInfo; defer delete(queue_create_infos)
		for family, count in &queue_families {
			append(&queue_create_infos, vulkan.DeviceQueueCreateInfo{
				sType = .DEVICE_QUEUE_CREATE_INFO,
				queueFamilyIndex = u32(family),
				queueCount = u32(count),
				pQueuePriorities = raw_data(queue_priorities),
			})
		}

		device_features := vulkan.PhysicalDeviceFeatures{}

		device_create_info := vulkan.DeviceCreateInfo{
			sType = .DEVICE_CREATE_INFO,
			queueCreateInfoCount = u32(len(queue_create_infos)),
			pQueueCreateInfos = raw_data(queue_create_infos),
			enabledExtensionCount = u32(len(device_extensions)),
			ppEnabledExtensionNames = raw_data(device_extensions),
			pEnabledFeatures = &device_features,
		}

		if result := vulkan.CreateDevice(physical_device, &device_create_info, nil, &device); result != .SUCCESS {
			fmt.eprintln("couldn't create vulkan device")
			return
		}

		vulkan.GetDeviceQueue(device, u32(queue_family_graphics_index), 0, &graphics_queue)
		if graphics_queue == nil {
			fmt.eprintln("couldn't create device queue")
			return
		}

		vulkan.GetDeviceQueue(device, u32(queue_family_present_index), 0, &present_queue)
		if present_queue == nil {
			fmt.eprintln("couldn't create present queue")
			return
		}
	}

	// lets get the swapchain working
	surface_format : vulkan.SurfaceFormatKHR
	present_mode   : vulkan.PresentModeKHR
	swap_extent    : vulkan.Extent2D
	swapchain      : vulkan.SwapchainKHR; defer vulkan.DestroySwapchainKHR(device, swapchain, nil)

	// also the image views for the framebuffers (what part of the framebuffer to use)
	swapchain_images      : [dynamic]vulkan.Image; defer delete(swapchain_images)
	swapchain_image_views : [dynamic]vulkan.ImageView; defer delete(swapchain_image_views)
	defer for siv in &swapchain_image_views do vulkan.DestroyImageView(device, siv, nil)

	{
		// find ideal format for surface
		ideal_format := false
		for f in &device_formats {
			if f.format == .B8G8R8A8_SRGB && f.colorSpace == .SRGB_NONLINEAR {
				surface_format = f
				ideal_format = true
				break
			}
		}
		if !ideal_format {
			surface_format = device_formats[0]
		}

		// find ideal mode for presentation
		ideal_present_mode := false
		for pm in &device_present_modes {
			if pm == .MAILBOX {
				present_mode = pm
				ideal_present_mode = true
				break
			}
		}
		if !ideal_present_mode {
			present_mode = .FIFO
		}

		// find ideal swap extent from capabilities or sdl2
		swap_extent = device_capabilities.currentExtent
		if swap_extent.width == max(u32) {
			width, height : c.int
			sdl2.Vulkan_GetDrawableSize(window, &width, &height)
			swap_extent.width = clamp(u32(width), device_capabilities.minImageExtent.width, device_capabilities.maxImageExtent.width)
			swap_extent.height = clamp(u32(height), device_capabilities.minImageExtent.height, device_capabilities.maxImageExtent.height)
		}

		// prefer min + 1 images on the swapchain but no more than max
		image_count := device_capabilities.minImageCount + 1
		if device_capabilities.maxImageCount > 0 && image_count > device_capabilities.maxImageCount {
			image_count = device_capabilities.maxImageCount
		}

		swapchain_create_info := vulkan.SwapchainCreateInfoKHR{
			sType = .SWAPCHAIN_CREATE_INFO_KHR,
			surface = surface,
			minImageCount = image_count,
			imageFormat = surface_format.format,
			imageColorSpace = surface_format.colorSpace,
			imageExtent = swap_extent,
			imageArrayLayers = 1,
			imageUsage = { .COLOR_ATTACHMENT },
			imageSharingMode = .EXCLUSIVE,
			preTransform = device_capabilities.currentTransform,
			compositeAlpha = { .OPAQUE },
			presentMode = present_mode,
			clipped = true,
		}

		// handle different queue families
		queue_families := []u32{ u32(queue_family_graphics_index), u32(queue_family_present_index) }
		if queue_family_graphics_index != queue_family_present_index {
			swapchain_create_info.imageSharingMode = .CONCURRENT
			swapchain_create_info.queueFamilyIndexCount = 2
			swapchain_create_info.pQueueFamilyIndices = raw_data(queue_families)
		}

		// finally the swapchain
		if vulkan.CreateSwapchainKHR(device, &swapchain_create_info, nil, &swapchain) != .SUCCESS {
			fmt.eprintln("couldn't create swapchain")
			return
		}

		// we can also get the images
		vulkan.GetSwapchainImagesKHR(device, swapchain, &image_count, nil)
		resize(&swapchain_images, int(image_count))
		vulkan.GetSwapchainImagesKHR(device, swapchain, &image_count, raw_data(swapchain_images))

		// and the image views for each image
		resize(&swapchain_image_views, len(swapchain_images))
		for i in 0 ..< len(swapchain_image_views) {
			image_view_create_info := vulkan.ImageViewCreateInfo{
				sType = .IMAGE_VIEW_CREATE_INFO,
				image = swapchain_images[i],
				viewType = .D2,
				format = surface_format.format,
				components = {
					r = .IDENTITY,
					g = .IDENTITY,
					b = .IDENTITY,
					a = .IDENTITY,
				},
				subresourceRange = {
					aspectMask = { .COLOR },
					baseMipLevel = 0,
					levelCount = 1,
					baseArrayLayer = 0,
					layerCount = 1,
				},
			}

			if vulkan.CreateImageView(device, &image_view_create_info, nil, &swapchain_image_views[i]) != .SUCCESS {
				fmt.eprintln("error creating image view", i)
			}
		}
	}

	// this details the behaviour of the input and output memory
	render_pass : vulkan.RenderPass; defer vulkan.DestroyRenderPass(device, render_pass, nil)
	{
		colour_attachment := vulkan.AttachmentDescription{
			format = surface_format.format,
			samples = { ._1 },
			loadOp = .CLEAR,
			storeOp = .STORE,
			stencilLoadOp = .DONT_CARE,
			stencilStoreOp = .DONT_CARE,
			initialLayout = .UNDEFINED,
			finalLayout = .PRESENT_SRC_KHR,
		}
		colour_attachment_ref := vulkan.AttachmentReference{
			attachment = 0,
			layout = .COLOR_ATTACHMENT_OPTIMAL,
		}
		subpass := vulkan.SubpassDescription{
			pipelineBindPoint = .GRAPHICS,
			colorAttachmentCount = 1,
			pColorAttachments = &colour_attachment_ref,
		}
		dependency := vulkan.SubpassDependency{
			srcSubpass = vulkan.SUBPASS_EXTERNAL,
			dstSubpass = 0,
			srcStageMask = { .COLOR_ATTACHMENT_OUTPUT },
			dstStageMask = { .COLOR_ATTACHMENT_OUTPUT },
			dstAccessMask = { .COLOR_ATTACHMENT_WRITE },
		}

		render_pass_info := vulkan.RenderPassCreateInfo{
			sType = .RENDER_PASS_CREATE_INFO,
			attachmentCount = 1,
			pAttachments = &colour_attachment,
			subpassCount = 1,
			pSubpasses = &subpass,
			dependencyCount = 1,
			pDependencies = &dependency,
		}

		if vulkan.CreateRenderPass(device, &render_pass_info, nil, &render_pass) != .SUCCESS {
			fmt.eprintln("couldn't create render pass")
			return
		}
	}

	// this pipeline holds the shaders and other state (vertex input, assembly, viewport, rasteriser, multisampling, colour blending)
	graphics_pipeline : vulkan.Pipeline; defer vulkan.DestroyPipeline(device, graphics_pipeline, nil)
	pipeline_layout   : vulkan.PipelineLayout; defer vulkan.DestroyPipelineLayout(device, pipeline_layout, nil)
	{
		// load the code
		vertex_shader_code := #load("./shaders/setup_sdl2_debug.vert.spv")
		fragment_shader_code := #load("./shaders/setup_sdl2_debug.frag.spv")

		// create the modules for each
		vertex_module_info := vulkan.ShaderModuleCreateInfo{
			sType = .SHADER_MODULE_CREATE_INFO,
			codeSize = len(vertex_shader_code),
			pCode = cast(^u32) raw_data(vertex_shader_code),
		}
		vertex_shader_module : vulkan.ShaderModule; defer vulkan.DestroyShaderModule(device, vertex_shader_module, nil)
		vulkan.CreateShaderModule(device, &vertex_module_info, nil, &vertex_shader_module)

		fragment_module_info := vulkan.ShaderModuleCreateInfo{
			sType = .SHADER_MODULE_CREATE_INFO,
			codeSize = len(fragment_shader_code),
			pCode = cast(^u32) raw_data(fragment_shader_code),
		}
		fragment_shader_module : vulkan.ShaderModule; defer vulkan.DestroyShaderModule(device, fragment_shader_module, nil)
		vulkan.CreateShaderModule(device, &fragment_module_info, nil, &fragment_shader_module)

		// create stage info for each
		vertex_stage_info := vulkan.PipelineShaderStageCreateInfo{
			sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
			stage = { .VERTEX },
			module = vertex_shader_module,
			pName = "main",
		}
		fragment_stage_info := vulkan.PipelineShaderStageCreateInfo{
			sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
			stage = { .FRAGMENT },
			module = fragment_shader_module,
			pName = "main",
		}
		shader_stages := []vulkan.PipelineShaderStageCreateInfo{ vertex_stage_info, fragment_stage_info }

		// state for vertex input
		vertex_input_info := vulkan.PipelineVertexInputStateCreateInfo{
			sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
		}
		// state for assembly
		input_assembly_info := vulkan.PipelineInputAssemblyStateCreateInfo{
			sType = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
			topology = .TRIANGLE_LIST,
			primitiveRestartEnable = false,
		}
		// state for viewport
		viewport := vulkan.Viewport{
			x = 0.0,
			y = 0.0,
			width = cast(f32) swap_extent.width,
			height = cast(f32) swap_extent.height,
			minDepth = 0.0,
			maxDepth = 1.0,
		}
		scissor := vulkan.Rect2D{
			offset = { 0, 0 },
			extent = swap_extent,
		}
		viewport_state := vulkan.PipelineViewportStateCreateInfo{
			sType = .PIPELINE_VIEWPORT_STATE_CREATE_INFO,
			viewportCount = 1,
			pViewports = &viewport,
			scissorCount = 1,
			pScissors = &scissor,
		}
		// state for rasteriser
		rasteriser := vulkan.PipelineRasterizationStateCreateInfo{
			sType = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
			depthClampEnable = false,
			rasterizerDiscardEnable = false,
			polygonMode = .FILL,
			lineWidth = 1.0,
			cullMode = { .BACK },
			frontFace = .CLOCKWISE,
			depthBiasEnable = false,
		}
		// state for multisampling
		multisampling := vulkan.PipelineMultisampleStateCreateInfo{
			sType = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
			sampleShadingEnable = false,
			rasterizationSamples = { ._1 },
		}
		// state for colour blending
		colour_blend_attachment := vulkan.PipelineColorBlendAttachmentState{
			colorWriteMask = { .R, .G, .B, .A },
			blendEnable = true,
			srcColorBlendFactor = .ONE,
			dstColorBlendFactor = .ZERO,
			colorBlendOp = .ADD,
			srcAlphaBlendFactor = .ONE,
			dstAlphaBlendFactor = .ZERO,
			alphaBlendOp = .ADD,
		}
		colour_blending := vulkan.PipelineColorBlendStateCreateInfo{
			sType = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
			logicOpEnable = false,
			logicOp = .COPY,
			attachmentCount = 1,
			pAttachments = &colour_blend_attachment,
			blendConstants = { 0.0, 0.0, 0.0, 0.0 },
		}

		// pipeline layout
		pipeline_layout_info := vulkan.PipelineLayoutCreateInfo{
			sType = .PIPELINE_LAYOUT_CREATE_INFO,
		}
		if vulkan.CreatePipelineLayout(device, &pipeline_layout_info, nil, &pipeline_layout) != .SUCCESS {
			fmt.eprintln("couldn't create pipeline layout")
			return
		}

		// pipeline finally
		pipeline_info := vulkan.GraphicsPipelineCreateInfo{
			sType = .GRAPHICS_PIPELINE_CREATE_INFO,
			stageCount = u32(len(shader_stages)),
			pStages = raw_data(shader_stages),
			pVertexInputState = &vertex_input_info,
			pInputAssemblyState = &input_assembly_info,
			pViewportState = &viewport_state,
			pRasterizationState = &rasteriser,
			pMultisampleState = &multisampling,
			pColorBlendState = &colour_blending,
			layout = pipeline_layout,
			renderPass = render_pass,
			subpass = 0,
		}

		if vulkan.CreateGraphicsPipelines(device, 0, 1, &pipeline_info, nil, &graphics_pipeline) != .SUCCESS {
			fmt.eprintln("couldn't create graphics pipeline")
			return
		}
	}

	// these framebuffers are what the render pass will use
	swapchain_framebuffers : [dynamic]vulkan.Framebuffer; defer delete(swapchain_framebuffers)
	defer for sf in &swapchain_framebuffers do vulkan.DestroyFramebuffer(device, sf, nil)
	{
		resize(&swapchain_framebuffers, len(swapchain_image_views))

		for i in 0 ..< len(swapchain_image_views) {
			attachments := []vulkan.ImageView{
				swapchain_image_views[i],
			}

			framebuffer_info := vulkan.FramebufferCreateInfo{
				sType = .FRAMEBUFFER_CREATE_INFO,
				renderPass = render_pass,
				attachmentCount = 1,
				pAttachments = raw_data(attachments),
				width = swap_extent.width,
				height = swap_extent.height,
				layers = 1,
			}

			if vulkan.CreateFramebuffer(device, &framebuffer_info, nil, &swapchain_framebuffers[i]) != .SUCCESS {
				fmt.eprintln("failed to create framebuffer", i)
				return
			}
		}
	}

	// these command buffers will hold the render commands
	command_pool    : vulkan.CommandPool; defer vulkan.DestroyCommandPool(device, command_pool, nil)
	command_buffers : [dynamic]vulkan.CommandBuffer; defer delete(command_buffers)
	{
		pool_info := vulkan.CommandPoolCreateInfo{
			sType = .COMMAND_POOL_CREATE_INFO,
			queueFamilyIndex = u32(queue_family_graphics_index),
		}
		if vulkan.CreateCommandPool(device, &pool_info, nil, &command_pool) != .SUCCESS {
			fmt.eprintln("couldn't create command pool")
			return
		}

		// we need a command buffer for each framebuffer
		resize(&command_buffers, len(swapchain_framebuffers))
		alloc_info := vulkan.CommandBufferAllocateInfo{
			sType = .COMMAND_BUFFER_ALLOCATE_INFO,
			commandPool = command_pool,
			level = .PRIMARY,
			commandBufferCount = u32(len(command_buffers)),
		}
		if vulkan.AllocateCommandBuffers(device, &alloc_info, raw_data(command_buffers)) != .SUCCESS {
			fmt.eprintln("couldn't allocate command buffers")
			return
		}

		for cb, i in &command_buffers {
			begin_info := vulkan.CommandBufferBeginInfo{
				sType = .COMMAND_BUFFER_BEGIN_INFO,
			}

			// wow here's the clear colour finally (a nice blue colour, srgb corrected)
			clear_colour := vulkan.ClearValue{
				color = { float32 = { 0.03561436968491878157417676879363, 0.22713652550514897375949232016547, 0.65237010541082120207337791500345, 1.0 } },
			}
			render_pass_info := vulkan.RenderPassBeginInfo{
				sType = .RENDER_PASS_BEGIN_INFO,
				renderPass = render_pass,
				framebuffer = swapchain_framebuffers[i],
				renderArea = {
					offset = { 0, 0 },
					extent = swap_extent,
				},
				clearValueCount = 1,
				pClearValues = &clear_colour,
			}

			vulkan.BeginCommandBuffer(cb, &begin_info)
			vulkan.CmdBeginRenderPass(cb, &render_pass_info, .INLINE)
			vulkan.CmdBindPipeline(cb, .GRAPHICS, graphics_pipeline)

			// this is it, this is the draw command
			vulkan.CmdDraw(cb, 3, 1, 0, 0)

			vulkan.CmdEndRenderPass(cb)
			if vulkan.EndCommandBuffer(cb) != .SUCCESS {
				fmt.eprintln("couldn't end command buffer", i)
				return
			}
		}
	}

	// syncronisation
	frames_in_flight := 2
	max_frames_in_flight := clamp(frames_in_flight, 0, len(swapchain_images))
	flight_frame := 0
	image_available_semaphores : [dynamic]vulkan.Semaphore; defer delete(image_available_semaphores)
	defer for ias in &image_available_semaphores do vulkan.DestroySemaphore(device, ias, nil)
	render_finished_semaphores : [dynamic]vulkan.Semaphore; defer delete(render_finished_semaphores)
	defer for rfs in &render_finished_semaphores do vulkan.DestroySemaphore(device, rfs, nil)
	in_flight_fences : [dynamic]vulkan.Fence; defer delete(in_flight_fences)
	defer for iff in &in_flight_fences do vulkan.DestroyFence(device, iff, nil)
	images_in_flight : [dynamic]vulkan.Fence; defer delete(images_in_flight)
	{
		resize(&image_available_semaphores, max_frames_in_flight)
		resize(&render_finished_semaphores, max_frames_in_flight)
		resize(&in_flight_fences, max_frames_in_flight)
		resize(&images_in_flight, len(swapchain_images))

		semaphore_info := vulkan.SemaphoreCreateInfo{
			sType = .SEMAPHORE_CREATE_INFO,
		}
		fence_info := vulkan.FenceCreateInfo{
			sType = .FENCE_CREATE_INFO,
			flags = { .SIGNALED },
		}
		for i in 0 ..< max_frames_in_flight {
			if vulkan.CreateSemaphore(device, &semaphore_info, nil, &image_available_semaphores[i]) != .SUCCESS ||
			vulkan.CreateSemaphore(device, &semaphore_info, nil, &render_finished_semaphores[i]) != .SUCCESS ||
			vulkan.CreateFence(device, &fence_info, nil, &in_flight_fences[i]) != .SUCCESS {
				fmt.eprintln("failed to create sync objects")
				return
			}
		}
	}

	running := true
	for running {
		// this is our event loop for input processing
		event : sdl2.Event
		for sdl2.PollEvent(&event) != 0 {
			if event.type == .QUIT {
				running = false
			}
			if event.type == .KEYDOWN && event.key.keysym.scancode == .ESCAPE {
				sdl2.PushEvent(&sdl2.Event{ type = .QUIT })
			}
		}

		// here we go (at a certain point in the tutorial, I came here,
		// but it was a tease cos I had to go back up to create the semaphores)
		vulkan.WaitForFences(device, 1, &in_flight_fences[flight_frame], true, max(u64))

		image_index : u32
		vulkan.AcquireNextImageKHR(device, swapchain, max(u64), image_available_semaphores[flight_frame], 0, &image_index)

		// async is a little bit of a nightmare is seems
		if images_in_flight[image_index] != 0 {
			vulkan.WaitForFences(device, 1, &images_in_flight[image_index], true, max(u64))
		}
		images_in_flight[image_index] = in_flight_fences[flight_frame]
		wait_semaphore := []vulkan.Semaphore{ image_available_semaphores[flight_frame] }
		signal_semaphore := []vulkan.Semaphore{ render_finished_semaphores[flight_frame] }
		flight_frame = (flight_frame + 1) & max_frames_in_flight

		submit_info := vulkan.SubmitInfo{
			sType = .SUBMIT_INFO,
			waitSemaphoreCount = u32(len(wait_semaphore)),
			pWaitSemaphores = raw_data(wait_semaphore),
			pWaitDstStageMask = &vulkan.PipelineStageFlags{ .COLOR_ATTACHMENT_OUTPUT },
			commandBufferCount = 1,
			pCommandBuffers = &command_buffers[image_index],
			signalSemaphoreCount = u32(len(signal_semaphore)),
			pSignalSemaphores = raw_data(signal_semaphore),
		}
		vulkan.ResetFences(device, 1, &in_flight_fences[flight_frame])
		vulkan.QueueSubmit(graphics_queue, 1, &submit_info, in_flight_fences[flight_frame])

		swapchains := []vulkan.SwapchainKHR{ swapchain }
		present_info := vulkan.PresentInfoKHR{
			sType = .PRESENT_INFO_KHR,
			waitSemaphoreCount = u32(len(signal_semaphore)),
			pWaitSemaphores = raw_data(signal_semaphore),
			swapchainCount = u32(len(swapchains)),
			pSwapchains = raw_data(swapchains),
			pImageIndices = &image_index,
		}
		vulkan.QueuePresentKHR(present_queue, &present_info)
		vulkan.QueueWaitIdle(present_queue)
	}

	// catch async problems
	vulkan.DeviceWaitIdle(device)
}
