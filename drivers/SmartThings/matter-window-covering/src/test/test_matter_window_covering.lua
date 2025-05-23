-- Copyright 2022 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local test = require "integration_test"
local capabilities = require "st.capabilities"
local t_utils = require "integration_test.utils"
local uint32 = require "st.matter.data_types.Uint32"
local clusters = require "st.matter.clusters"
local WindowCovering = clusters.WindowCovering

local mock_device = test.mock_device.build_test_matter_device(
  {
    profile = t_utils.get_profile_definition("window-covering-tilt-battery.yml"),
    manufacturer_info = {vendor_id = 0x0000, product_id = 0x0000},
    preferences = { presetPosition = 30 },
    endpoints = {
      {
        endpoint_id = 2,
        clusters = {
          {cluster_id = clusters.Basic.ID, cluster_type = "SERVER"},
        },
        device_types = {
          device_type_id = 0x0016, device_type_revision = 1, -- RootNode
        }
      },
      {
        endpoint_id = 10,
        clusters = { -- list the clusters
          {
            cluster_id = clusters.WindowCovering.ID,
            cluster_type = "SERVER",
            cluster_revision = 1,
            feature_map = 3,
          },
          {cluster_id = clusters.LevelControl.ID, cluster_type = "SERVER"},
          {cluster_id = clusters.PowerSource.ID, cluster_type = "SERVER", feature_map = 0x0002}
        },
      },
    },
  }
)

local mock_device_switch_to_battery = test.mock_device.build_test_matter_device(
  {
    profile = t_utils.get_profile_definition("window-covering.yml"),
    manufacturer_info = {vendor_id = 0x0000, product_id = 0x0000},
    preferences = { presetPosition = 30 },
    endpoints = {
      {
        endpoint_id = 2,
        clusters = {
          {cluster_id = clusters.Basic.ID, cluster_type = "SERVER"},
        },
        device_types = {
          device_type_id = 0x0016, device_type_revision = 1, -- RootNode
        }
      },
      {
        endpoint_id = 10,
        clusters = { -- list the clusters
          {
            cluster_id = clusters.WindowCovering.ID,
            cluster_type = "SERVER",
            cluster_revision = 1,
            feature_map = 1,
          },
          {cluster_id = clusters.LevelControl.ID, cluster_type = "SERVER"},
          {cluster_id = clusters.PowerSource.ID, cluster_type = "SERVER", feature_map = 0x0002}
        },
      },
    },
  }
)

local mock_device_mains_powered = test.mock_device.build_test_matter_device(
  {
    profile = t_utils.get_profile_definition("window-covering.yml"),
    manufacturer_info = {vendor_id = 0x0000, product_id = 0x0000},
    preferences = { presetPosition = 30 },
    endpoints = {
      {
        endpoint_id = 2,
        clusters = {
          {cluster_id = clusters.Basic.ID, cluster_type = "SERVER"},
        },
        device_types = {
          device_type_id = 0x0016, device_type_revision = 1, -- RootNode
        }
      },
      {
        endpoint_id = 10,
        clusters = { -- list the clusters
          {
            cluster_id = clusters.WindowCovering.ID,
            cluster_type = "SERVER",
            cluster_revision = 1,
            feature_map = 1,
          },
          {cluster_id = clusters.LevelControl.ID, cluster_type = "SERVER"},
          {cluster_id = clusters.PowerSource.ID, cluster_type = "SERVER", feature_map = 0x0001}
        },
      },
    },
  }
)

local CLUSTER_SUBSCRIBE_LIST = {
  clusters.LevelControl.server.attributes.CurrentLevel,
  WindowCovering.server.attributes.CurrentPositionLiftPercent100ths,
  WindowCovering.server.attributes.CurrentPositionTiltPercent100ths,
  WindowCovering.server.attributes.OperationalStatus,
  clusters.PowerSource.server.attributes.BatPercentRemaining
}

local CLUSTER_SUBSCRIBE_LIST_NO_BATTERY = {
  clusters.LevelControl.server.attributes.CurrentLevel,
  WindowCovering.server.attributes.CurrentPositionLiftPercent100ths,
  WindowCovering.server.attributes.OperationalStatus,
}

local function test_init()
  local subscribe_request = CLUSTER_SUBSCRIBE_LIST[1]:subscribe(mock_device)
  for i, clus in ipairs(CLUSTER_SUBSCRIBE_LIST) do
    if i > 1 then subscribe_request:merge(clus:subscribe(mock_device)) end
  end
  test.socket.matter:__expect_send({mock_device.id, subscribe_request})
  test.mock_device.add_test_device(mock_device)
end

local function test_init_switch_to_battery()
  local subscribe_request = CLUSTER_SUBSCRIBE_LIST_NO_BATTERY[1]:subscribe(mock_device_switch_to_battery)
  for i, clus in ipairs(CLUSTER_SUBSCRIBE_LIST_NO_BATTERY) do
    if i > 1 then subscribe_request:merge(clus:subscribe(mock_device_switch_to_battery)) end
  end
  test.socket.matter:__expect_send({mock_device_switch_to_battery.id, subscribe_request})
  test.mock_device.add_test_device(mock_device_switch_to_battery)
  test.socket.device_lifecycle:__queue_receive({ mock_device_switch_to_battery.id, "doConfigure" })
  mock_device_switch_to_battery:expect_metadata_update({ provisioning_state = "PROVISIONED" })
  local read_attribute_list = clusters.PowerSource.attributes.AttributeList:read()
  test.socket.matter:__expect_send({mock_device_switch_to_battery.id, read_attribute_list})
end

local function test_init_mains_powered()
  local subscribe_request = CLUSTER_SUBSCRIBE_LIST_NO_BATTERY[1]:subscribe(mock_device_mains_powered)
  for i, clus in ipairs(CLUSTER_SUBSCRIBE_LIST_NO_BATTERY) do
    if i > 1 then subscribe_request:merge(clus:subscribe(mock_device_mains_powered)) end
  end
  test.socket.matter:__expect_send({mock_device_mains_powered.id, subscribe_request})
  test.mock_device.add_test_device(mock_device_mains_powered)
  test.socket.device_lifecycle:__queue_receive({ mock_device_mains_powered.id, "doConfigure" })
  mock_device_mains_powered:expect_metadata_update({ profile = "window-covering" })
  mock_device_mains_powered:expect_metadata_update({ provisioning_state = "PROVISIONED" })
end

test.set_test_init_function(test_init)

test.register_coroutine_test(
  "WindowCovering OperationalStatus state closed following lift position update", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, 10000
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(0)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.closed()
      )
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
  end
)

test.register_coroutine_test(
  "WindowCovering OperationalStatus state closed following tilt position update", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionTiltPercent100ths:build_test_report_data(
          mock_device, 10, 10000
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeTiltLevel.shadeTiltLevel(0)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.closed()
      )
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
  end
)

test.register_coroutine_test(
  "WindowCovering OperationalStatus state closed before lift position 0", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, 10000
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(0)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.closed()
      )
    )
  end
)

test.register_coroutine_test(
  "WindowCovering OperationalStatus state closed before tilt position 0", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionTiltPercent100ths:build_test_report_data(
          mock_device, 10, 10000
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeTiltLevel.shadeTiltLevel(0)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.closed()
      )
    )
  end
)

test.register_coroutine_test(
  "WindowCovering OperationalStatus state open following lift position update", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, 0
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(100)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.open()
      )
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
  end
)

test.register_coroutine_test(
  "WindowCovering OperationalStatus state open following tilt position update", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionTiltPercent100ths:build_test_report_data(
          mock_device, 10, 0
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeTiltLevel.shadeTiltLevel(100)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.open()
      )
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
  end
)

test.register_coroutine_test(
  "WindowCovering OperationalStatus state open before lift position event", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(100)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.open()
      )
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, 0
        ),
      }
    )
  end
)

test.register_coroutine_test(
  "WindowCovering OperationalStatus state open before tilt position event", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeTiltLevel.shadeTiltLevel(100)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.open()
      )
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionTiltPercent100ths:build_test_report_data(
          mock_device, 10, 0
        ),
      }
    )
  end
)

test.register_coroutine_test(
  "WindowCovering OperationalStatus partially open following lift position update", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 25) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(25)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
  end
)

test.register_coroutine_test(
  "WindowCovering OperationalStatus partially open following tilt position update", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionTiltPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 15) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeTiltLevel.shadeTiltLevel(15)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
  end
)

test.register_coroutine_test(
  "WindowCovering OperationalStatus partially open before lift position event", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 25) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(25)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
  end
)

test.register_coroutine_test(
  "WindowCovering OperationalStatus partially open before tilt position event", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionTiltPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 65) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeTiltLevel.shadeTiltLevel(65)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
  end
)

test.register_coroutine_test("WindowCovering OperationalStatus opening", function()
  test.socket.capability:__set_channel_ordering("relaxed")
  test.socket.matter:__queue_receive(
    {
      mock_device.id,
      WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
        mock_device, 10, ((100 - 25) *100)
      ),
    }
  )
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShadeLevel.shadeLevel(25)
    )
  )
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShade.windowShade.partially_open()
    )
  )
  test.socket.matter:__queue_receive(
    {
      mock_device.id,
      WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 1),
    }
  )
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShade.windowShade.opening()
    )
  )
end)

test.register_coroutine_test("WindowCovering OperationalStatus closing", function()
  test.socket.capability:__set_channel_ordering("relaxed")
  test.socket.matter:__queue_receive(
    {
      mock_device.id,
      WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
        mock_device, 10, ((100 - 25) *100)
      ),
    }
  )
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShadeLevel.shadeLevel(25)
    )
  )
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShade.windowShade.partially_open()
    )
  )
  test.socket.matter:__queue_receive(
    {
      mock_device.id,
      WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 2),
    }
  )
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShade.windowShade.closing()
    )
  )
end)

test.register_coroutine_test("WindowCovering OperationalStatus unknown", function()
  test.socket.capability:__set_channel_ordering("relaxed")
  test.socket.matter:__queue_receive(
    {
      mock_device.id,
      WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
        mock_device, 10, ((100 - 25) *100)
      ),
    }
  )
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShadeLevel.shadeLevel(25)
    )
  )
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShade.windowShade.partially_open()
    )
  )
  test.socket.matter:__queue_receive(
    {
      mock_device.id,
      WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 3),
    }
  )
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShade.windowShade.unknown()
    )
  )
end)

test.register_coroutine_test(
  "WindowShade open cmd handler", function()
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        {capability = "windowShade", component = "main", command = "open", args = {}},
      }
    )
    test.socket.matter:__expect_send(
      {mock_device.id, WindowCovering.server.commands.UpOrOpen(mock_device, 10)}
    )
    test.wait_for_events()
  end
)

test.register_coroutine_test(
  "WindowShade close cmd handler", function()
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        {capability = "windowShade", component = "main", command = "close", args = {}},
      }
    )
    test.socket.matter:__expect_send(
      {mock_device.id, WindowCovering.server.commands.DownOrClose(mock_device, 10)}
    )
    test.wait_for_events()
  end
)

test.register_coroutine_test(
  "WindowShade pause cmd handler", function()
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        {capability = "windowShade", component = "main", command = "pause", args = {}},
      }
    )
    test.socket.matter:__expect_send(
      {mock_device.id, WindowCovering.server.commands.StopMotion(mock_device, 10)}
    )
    test.wait_for_events()
  end
)

test.register_coroutine_test(
  "Refresh necessary attributes", function()
    test.socket.device_lifecycle:__queue_receive({mock_device.id, "added"})
    test.socket.capability:__expect_send(
      {
        mock_device.id,
        {
          capability_id = "windowShade",
          component_id = "main",
          attribute_id = "supportedWindowShadeCommands",
          state = {value = {"open", "close", "pause"}},
          visibility = {displayed = false}
        },
      }
    )
    test.wait_for_events()

    test.socket.capability:__queue_receive(
      {mock_device.id, {capability = "refresh", component = "main", command = "refresh", args = {}}}
    )
    local read_request = CLUSTER_SUBSCRIBE_LIST[1]:read(mock_device)
    for i, attr in ipairs(CLUSTER_SUBSCRIBE_LIST) do
      if i > 1 then read_request:merge(attr:read(mock_device)) end
    end
    test.socket.matter:__expect_send({mock_device.id, read_request})
    test.wait_for_events()
  end
)

test.register_coroutine_test("WindowShade setShadeLevel cmd handler", function()
  test.socket.capability:__queue_receive(
    {
      mock_device.id,
      {capability = "windowShadeLevel", component = "main", command = "setShadeLevel", args = { 20 }},
    }
  )
  test.socket.matter:__expect_send(
    {mock_device.id, WindowCovering.server.commands.GoToLiftPercentage(mock_device, 10, 8000)}
  )
end)

test.register_coroutine_test("WindowShade setShadeTiltLevel cmd handler", function()
  test.socket.capability:__queue_receive(
    {
      mock_device.id,
      {capability = "windowShadeTiltLevel", component = "main", command = "setShadeTiltLevel", args = { 60 }},
    }
  )
  test.socket.matter:__expect_send(
    {mock_device.id, WindowCovering.server.commands.GoToTiltPercentage(mock_device, 10, 4000)}
  )
end)

test.register_coroutine_test("LevelControl CurrentLevel handler", function()
  test.socket.matter:__queue_receive(
    {
      mock_device.id,
      clusters.LevelControl.attributes.CurrentLevel:build_test_report_data(mock_device, 10, 100),
    }
  )
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShadeLevel.shadeLevel(math.floor((100 / 254.0 * 100) + .5))
    )
  )
end)

--test battery
test.register_coroutine_test(
  "Battery percent reports should generate correct messages", function()
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        clusters.PowerSource.attributes.BatPercentRemaining:build_test_report_data(
          mock_device, 10, 150
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.battery.battery(math.floor(150/2.0+0.5))
      )
    )
  end
)

test.register_coroutine_test("OperationalStatus report contains current position report", function()
  test.socket.capability:__set_channel_ordering("relaxed")
  local report = WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
    mock_device, 10, ((100 - 25) *100)
  )
  table.insert(report.info_blocks, WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0).info_blocks[1])
  test.socket.matter:__queue_receive({ mock_device.id, report})
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShadeLevel.shadeLevel(25)
    )
  )
  test.socket.capability:__expect_send(
    mock_device:generate_test_message(
      "main", capabilities.windowShade.windowShade.partially_open()
    )
  )
end)

test.register_coroutine_test("Handle windowcoveringPreset", function()
  test.socket.capability:__queue_receive(
    {
      mock_device.id,
      {capability = "windowShadePreset", component = "main", command = "presetPosition", args = {}},
    }
  )
  test.socket.matter:__expect_send(
    {mock_device.id, WindowCovering.server.commands.GoToLiftPercentage(mock_device, 10, 7000)}
  )
  test.socket.matter:__expect_send(
    {mock_device.id, WindowCovering.server.commands.GoToTiltPercentage(mock_device, 10, 5000)}
  )
end)

test.register_coroutine_test(
  "Test profile change to window-covering-battery when battery percent remaining attribute (attribute ID 12) is available",
  function()
    test.socket.matter:__queue_receive(
      {
        mock_device_switch_to_battery.id,
        clusters.PowerSource.attributes.AttributeList:build_test_report_data(mock_device_switch_to_battery, 10, {uint32(12)})
      }
    )
    mock_device_switch_to_battery:expect_metadata_update({ profile = "window-covering-battery" })
  end,
  { test_init = test_init_switch_to_battery }
)

test.register_coroutine_test(
  "Test that profile is not changed to window-covering-battery when battery percent remaining attribute (attribute ID 12) is not available",
  function()
    test.socket.matter:__queue_receive(
      {
        mock_device_switch_to_battery.id,
        clusters.PowerSource.attributes.AttributeList:build_test_report_data(mock_device_switch_to_battery, 10, {uint32(10)})
      }
    )
  end,
  { test_init = test_init_switch_to_battery }
)

test.register_coroutine_test(
  "Test mains powered device does not switch to battery profile",
  function()
  end,
  { test_init = test_init_mains_powered }
)

test.register_coroutine_test(
  "InfoChanged event checks for new profile match if device has changed (i.e. through reinterview or SW update)",
  function()
    test.socket.device_lifecycle:__queue_receive(mock_device:generate_info_changed({}))
    local read_attribute_list = clusters.PowerSource.attributes.AttributeList:read()
    test.socket.matter:__expect_send({mock_device.id, read_attribute_list})
    test.wait_for_events()
    test.socket.matter:__queue_receive({mock_device.id, clusters.PowerSource.attributes.AttributeList:build_test_report_data(mock_device, 10, {uint32(0x0C)})})
    mock_device:expect_metadata_update({profile = "window-covering-tilt-battery"})
  end
)

test.register_coroutine_test(
  "WindowCovering shade level adjusted by greater than 2%; status reflects Closing followed by Partially Open", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 25) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(25)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
    test.wait_for_events()
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        {capability = "windowShadeLevel", component = "main", command = "setShadeLevel", args = { 19 }},
      }
    )
    test.socket.matter:__expect_send(
      {mock_device.id, WindowCovering.server.commands.GoToLiftPercentage(mock_device, 10, 8100)}
    )
    test.wait_for_events()
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 10),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.closing()
      )
    )
    test.wait_for_events()
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 23) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(23)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
    test.wait_for_events()
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 21) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(21)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
    test.wait_for_events()
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 19) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
          "main", capabilities.windowShadeLevel.shadeLevel(19)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
  end
)

test.register_coroutine_test(
  "WindowCovering shade level adjusted by less than or equal to 2%; status reflects Closing followed by Partially Open", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 0),
      }
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 25) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(25)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
    test.wait_for_events()
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        {capability = "windowShadeLevel", component = "main", command = "setShadeLevel", args = { 23 }},
      }
    )
    test.socket.matter:__expect_send(
      {mock_device.id, WindowCovering.server.commands.GoToLiftPercentage(mock_device, 10, 7700)}
    )
    test.wait_for_events()
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.OperationalStatus:build_test_report_data(mock_device, 10, 10),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.closing()
      )
    )
    test.wait_for_events()
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 23) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(23)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
  end
)

test.register_coroutine_test(
  "Check that preference updates to reverse polarity after being set to true and that the shade lift operates as expected when opening and closing", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.device_lifecycle():__queue_receive(mock_device:generate_info_changed({ preferences = { reverse = "true" } }))
    test.wait_for_events()
    local reverse_preference_set = mock_device:get_field("__reverse_polarity")
    assert(reverse_preference_set == true, "reverse_preference_set is True")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 25) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(75)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 40) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeLevel.shadeLevel(60)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        {capability = "windowShadeLevel", component = "main", command = "setShadeLevel", args = { 85 }},
      }
    )
    test.socket.matter:__expect_send(
      {mock_device.id, WindowCovering.server.commands.GoToLiftPercentage(mock_device, 10, 8500)}
    )
  end
)

test.register_coroutine_test(
  "Check that preference updates to reverse polarity after being set to true and that the shade tilt operates as expected when opening and closing", function()
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.device_lifecycle():__queue_receive(mock_device:generate_info_changed({ preferences = { reverse = "true" } }))
    test.wait_for_events()
    local reverse_preference_set = mock_device:get_field("__reverse_polarity")
    assert(reverse_preference_set == true, "reverse_preference_set is True")
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionTiltPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 30) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeTiltLevel.shadeTiltLevel(70)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
    test.socket.matter:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionTiltPercent100ths:build_test_report_data(
          mock_device, 10, ((100 - 65) *100)
        ),
      }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShadeTiltLevel.shadeTiltLevel(35)
      )
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message(
        "main", capabilities.windowShade.windowShade.partially_open()
      )
    )
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        {capability = "windowShadeTiltLevel", component = "main", command = "setShadeTiltLevel", args = { 15 }},
      }
    )
    test.socket.matter:__expect_send(
      {mock_device.id, WindowCovering.server.commands.GoToTiltPercentage(mock_device, 10, 1500)}
    )
  end
)

test.run_registered_tests()
