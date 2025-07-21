-- Copyright 2025 SmartThings
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

-- Mock out globals
local test = require "integration_test"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"
local t_utils = require "integration_test.utils"
local data_types = require "st.zigbee.data_types"
local cluster_base = require "st.zigbee.cluster_base"

local PRIVATE_CLUSTER_ID = 0xFCC9
local MFG_CODE = 0x1235

local mock_device = test.mock_device.build_test_zigbee_device(
    { profile = t_utils.get_profile_definition("window-treatment-profile-screen-VIVIDSTORM.yml"),
      fingerprinted_endpoint_id = 0x01,
      zigbee_endpoints = {
        [1] = {
          id = 1,
          manufacturer = "VIVIDSTORM",
          model = "VWSDSTUST120H",
          server_clusters = {0x0000, 0x0102, 0xFCC9}
        }
      }
    }
)

zigbee_test_utils.prepare_zigbee_env_info()
local function test_init()
  test.mock_device.add_test_device(mock_device)
  zigbee_test_utils.init_noop_health_check_timer()
end

test.set_test_init_function(test_init)

test.register_coroutine_test(
  "capability - refresh",
  function()
    test.socket.capability:__queue_receive({ mock_device.id,
      { capability = "refresh", component = "main", command = "refresh", args = {} } })

    local read_0x0000_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0000, MFG_CODE)
    local read_0x0001_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0001, MFG_CODE)
	test.socket.zigbee:__expect_send({mock_device.id,
        clusters.WindowCovering.attributes.CurrentPositionLiftPercentage:read(mock_device)
    })
    test.socket.zigbee:__expect_send({mock_device.id, read_0x0000_messge})
    test.socket.zigbee:__expect_send({mock_device.id, read_0x0001_messge})
  end
)

test.register_coroutine_test(
  "lifecycle - added test",
  function()
    test.socket.device_lifecycle:__queue_receive({ mock_device.id, "added" })
    test.socket.capability:__expect_send(mock_device:generate_test_message("Setlimit", capabilities.mode.supportedModes({"设置上限位", "设置下限位", "删除所有限位"})))
    test.socket.capability:__expect_send(mock_device:generate_test_message("Setlimit", capabilities.mode.mode("设置上限位")))
	test.socket.capability:__expect_send(mock_device:generate_test_message("hardwareFault", capabilities.hardwareFault.hardwareFault.clear()))
	
	local read_0x0000_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0000, MFG_CODE)
    local read_0x0001_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0001, MFG_CODE)
	test.socket.zigbee:__expect_send({mock_device.id,
        clusters.WindowCovering.attributes.CurrentPositionLiftPercentage:read(mock_device)
    })
    test.socket.zigbee:__expect_send({mock_device.id, read_0x0000_messge})
    test.socket.zigbee:__expect_send({mock_device.id, read_0x0001_messge})
  end
)

test.register_message_test(
    "Handle Window shade open command",
    {
      {
        channel = "capability",
        direction = "receive",
        message = {
          mock_device.id,
          {
            capability = "windowShade", component = "Open", command = "open", args = {}
          }
        }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = { mock_device.id, clusters.WindowCovering.server.commands.UpOrOpen(mock_device) }
      }
    }
)

test.register_message_test(
    "Handle Window shade close command",
    {
      {
        channel = "capability",
        direction = "receive",
        message = {
          mock_device.id,
          {
            capability = "windowShade", component = "Open", command = "close", args = {}
          }
        }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = {
          mock_device.id,
          clusters.WindowCovering.server.commands.DownOrClose(mock_device)
        }
      }
    }
)

test.register_message_test(
    "Handle Window shade pause command",
    {
      {
        channel = "capability",
        direction = "receive",
        message = { mock_device.id, { capability = "windowShade", component = "Open", command = "pause", args = {} } }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = {
          mock_device.id,
          clusters.WindowCovering.server.commands.Stop(mock_device)
        }
      }
    }
)

test.register_coroutine_test(
  "Handle Setlimit 设置上限位",
  function()
    test.socket.capability:__queue_receive({
      mock_device.id,
      { capability = "mode", component = "Setlimit",  command ="setMode" , args = {"设置上限位"}}
    })
    test.socket.zigbee:__expect_send({ mock_device.id,
      cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
        0x0000, MFG_CODE, data_types.Uint8, 0)
    })
  end
)

test.register_coroutine_test(
  "Handle Setlimit 设置下限位",
  function()
    test.socket.capability:__queue_receive({
      mock_device.id,
      { capability = "mode", component = "Setlimit",  command ="setMode" , args = {"设置下限位"}}
    })
    test.socket.zigbee:__expect_send({ mock_device.id,
      cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
        0x0000, MFG_CODE, data_types.Uint8, 1)
    })
  end
)

test.register_coroutine_test(
  "Handle Setlimit 删除所有限位",
  function()
    test.socket.capability:__queue_receive({
      mock_device.id,
      { capability = "mode", component = "Setlimit",  command ="setMode" , args = {"删除所有限位"}}
    })
    test.socket.zigbee:__expect_send({ mock_device.id,
      cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
        0x0000, MFG_CODE, data_types.Uint8, 2)
    })
  end
)

test.register_coroutine_test(
  "Device reported Setlimit 0 and driver emit capabilities.mode.mode 0",
  function()
    local attr_report_data = {
      { 0x0000, data_types.Uint8.ID, 0 }
    }
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
    })
    test.socket.capability:__expect_send(mock_device:generate_test_message("Setlimit",
      capabilities.mode.mode("设置上限位")))
  end
)

test.register_coroutine_test(
  "Device reported Setlimit 1 and driver emit capabilities.mode.mode 1",
  function()
    local attr_report_data = {
      { 0x0000, data_types.Uint8.ID, 1 }
    }
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
    })
    test.socket.capability:__expect_send(mock_device:generate_test_message("Setlimit",
      capabilities.mode.mode("设置下限位")))
  end
)

test.register_coroutine_test(
  "Device reported Setlimit 2 and driver emit capabilities.mode.mode 2",
  function()
    local attr_report_data = {
      { 0x0000, data_types.Uint8.ID, 2 }
    }
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
    })
    test.socket.capability:__expect_send(mock_device:generate_test_message("Setlimit",
      capabilities.mode.mode("删除所有限位")))
  end
)

test.register_coroutine_test(
  "Device reported hardwareFault 0 and driver emit capabilities.hardwareFault.hardwareFault.clear()",
  function()
    local attr_report_data = {
      { 0x0001, data_types.Uint8.ID, 0 }
    }
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
    })
    test.socket.capability:__expect_send(mock_device:generate_test_message("hardwareFault",
      capabilities.hardwareFault.hardwareFault.clear()))
  end
)

test.register_coroutine_test(
  "Device reported hardwareFault 1 and driver emit capabilities.hardwareFault.hardwareFault.detected()",
  function()
    local attr_report_data = {
      { 0x0001, data_types.Uint8.ID, 1 }
    }
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
    })
    test.socket.capability:__expect_send(mock_device:generate_test_message("hardwareFault",
      capabilities.hardwareFault.hardwareFault.detected()))
  end
)

test.register_message_test(
  "WindowCovering CurrentPositionLiftPercentage report 10 emit opening",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_device.id, clusters.WindowCovering.attributes.CurrentPositionLiftPercentage:build_test_attr_report(mock_device, 10) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device:generate_test_message("Open", capabilities.windowShade.windowShade.opening())
    }
  }
)

test.register_message_test(
  "WindowCovering CurrentPositionLiftPercentage report 100 emit open",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_device.id, clusters.WindowCovering.attributes.CurrentPositionLiftPercentage:build_test_attr_report(mock_device, 100) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device:generate_test_message("Open", capabilities.windowShade.windowShade.opening())
    }
  }
)

test.register_message_test(
  "WindowCovering CurrentPositionLiftPercentage report 1 emit closing",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_device.id, clusters.WindowCovering.attributes.CurrentPositionLiftPercentage:build_test_attr_report(mock_device, 1) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device:generate_test_message("Open", capabilities.windowShade.windowShade.closing())
    }
  }
)

test.run_registered_tests()
