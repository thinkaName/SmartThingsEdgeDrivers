-- Copyright 2023 SmartThings
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
local clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"
local test = require "integration_test"
local t_utils = require "integration_test.utils"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"

local OnOff = clusters.OnOff

local common_switch_profile_def = t_utils.get_profile_definition("switch-smart-bath-heater-laisiao.yml")

local mock_simple_device = test.mock_device.build_test_zigbee_device(
  {
    label = "智能浴霸",
    profile = common_switch_profile_def,
    zigbee_endpoints = {
      [1] = {
        id = 1,
        manufacturer = "LAISIAO",
        model = "yuba",
        server_clusters = { 0x0006 }
      }
    },
  }
)

zigbee_test_utils.prepare_zigbee_env_info()

local function test_init()
  test.mock_device.add_test_device(mock_simple_device)
  zigbee_test_utils.init_noop_health_check_timer()
end

test.set_test_init_function(test_init)

test.register_message_test(
    "Reported on status should be handled: on ep 1",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                true):from_endpoint(0x01) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("main",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "Reported on status should be handled: on ep 2",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                true):from_endpoint(0x02) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch2",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "Reported on status should be handled: on ep 3",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                true):from_endpoint(0x03) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch3",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "Reported on status should be handled: on ep 4",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                true):from_endpoint(0x04) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch4",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "Reported on status should be handled: on ep 5",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                true):from_endpoint(0x05) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch5",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "Reported on status should be handled: on ep 6",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                true):from_endpoint(0x06) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch6",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "Reported on status should be handled: on ep 7",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                true):from_endpoint(0x07) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch7",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "Reported on status should be handled: on ep 8",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                true):from_endpoint(0x08) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch8",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "Reported on status should be handled: on ep 9",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                true):from_endpoint(0x09) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch9",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "Reported off status should be handled: off ep 1",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                false):from_endpoint(0x01) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("main",  capabilities.switch.switch.off())
      }
    }
)

test.register_message_test(
    "Reported off status should be handled: off ep 2",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                false):from_endpoint(0x02) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch2",  capabilities.switch.switch.off())
      }
    }
)

test.register_message_test(
    "Reported off status should be handled: off ep 3",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                false):from_endpoint(0x03) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch3",  capabilities.switch.switch.off())
      }
    }
)

test.register_message_test(
    "Reported off status should be handled: off ep 4",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                false):from_endpoint(0x04) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch4",  capabilities.switch.switch.off())
      }
    }
)

test.register_message_test(
    "Reported off status should be handled: off ep 5",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                false):from_endpoint(0x05) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch5",  capabilities.switch.switch.off())
      }
    }
)

test.register_message_test(
    "Reported off status should be handled: off ep 6",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                false):from_endpoint(0x06) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch6",  capabilities.switch.switch.off())
      }
    }
)

test.register_message_test(
    "Reported off status should be handled: off ep 7",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                false):from_endpoint(0x07) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch7",  capabilities.switch.switch.off())
      }
    }
)

test.register_message_test(
    "Reported off status should be handled: off ep 8",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                false):from_endpoint(0x08) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch8",  capabilities.switch.switch.off())
      }
    }
)

test.register_message_test(
    "Reported off status should be handled: off ep 9",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_simple_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_simple_device,
                                                                                                false):from_endpoint(0x09) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_simple_device:generate_test_message("switch9",  capabilities.switch.switch.off())
      }
    }
)

test.run_registered_tests()
