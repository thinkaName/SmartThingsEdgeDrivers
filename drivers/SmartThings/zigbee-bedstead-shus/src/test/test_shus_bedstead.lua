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
local test = require "integration_test"
local cluster_base = require "st.zigbee.cluster_base"
local data_types = require "st.zigbee.data_types"
local t_utils = require "integration_test.utils"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local custom_capabilities = require "shus/custom_capabilities"

local shus_bedstead_profile_def = t_utils.get_profile_definition("shus-smart-bedstead.yaml")
test.add_package_capability("massageControl.yaml")
test.add_package_capability("mode.yaml")
test.add_package_capability("movementControl.yaml")
test.add_package_capability("nightLight.yaml")

local PRIVATE_CLUSTER_ID = 0xFCC1
local MFG_CODE = 0x1235

local mock_device = test.mock_device.build_test_zigbee_device(
{
    label = "Shus Smart Bedstead",
    profile = shus_bedstead_profile_def,
    zigbee_endpoints = {
        [1] = {
            id = 1,
            manufacturer = "SHUS",
            model = "2123",
            server_clusters = { 0x0000,PRIVATE_CLUSTER_ID }
        }
    }
})

zigbee_test_utils.prepare_zigbee_env_info()
local function test_init()
    test.mock_device.add_test_device(mock_device)
    zigbee_test_utils.init_noop_health_check_timer()
end

test.set_test_init_function(test_init)

test.register_coroutine_test(
    "lifecycle - added test",
    function()
        test.socket.device_lifecycle:__queue_receive({ mock_device.id, "added" })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.movement_control.back.down() ))
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.movement_control.leg.down() ))
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.movement_control.backLeg.down() ))
        local read_0x0003_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0003, MFG_CODE)
        local read_0x0004_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0004, MFG_CODE)
        local read_0x0005_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0005, MFG_CODE)
        local read_0x0006_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0006, MFG_CODE)
        local read_0x000b_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x000b, MFG_CODE)
        local read_0x000c_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x000c, MFG_CODE)
        test.socket.zigbee:__expect_send({mock_device.id, read_0x0003_messge})
        test.socket.zigbee:__expect_send({mock_device.id, read_0x0004_messge})
        test.socket.zigbee:__expect_send({mock_device.id, read_0x0005_messge})
        test.socket.zigbee:__expect_send({mock_device.id, read_0x0006_messge})
        test.socket.zigbee:__expect_send({mock_device.id, read_0x000b_messge})
        test.socket.zigbee:__expect_send({mock_device.id, read_0x000c_messge})
    end
)

test.register_coroutine_test(
    "capability - refresh",
    function()
        test.socket.capability:__queue_receive({ mock_device.id,
            { capability = "refresh", component = "main", command = "refresh", args = {} } })
        local read_0x0003_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0003, MFG_CODE)
        local read_0x0004_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0004, MFG_CODE)
        local read_0x0005_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0005, MFG_CODE)
        local read_0x0006_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x0006, MFG_CODE)
        local read_0x000b_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x000b, MFG_CODE)
        local read_0x000c_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID, 0x000c, MFG_CODE)
        test.socket.zigbee:__expect_send({mock_device.id, read_0x0003_messge})
        test.socket.zigbee:__expect_send({mock_device.id, read_0x0004_messge})
        test.socket.zigbee:__expect_send({mock_device.id, read_0x0005_messge})
        test.socket.zigbee:__expect_send({mock_device.id, read_0x0006_messge})
        test.socket.zigbee:__expect_send({mock_device.id, read_0x000b_messge})
        test.socket.zigbee:__expect_send({mock_device.id, read_0x000c_messge})
    end
)

test.register_coroutine_test(
    "Device reported back 0 and driver emit movement_control.back.down()",
    function()
        local attr_report_data = {
            { 0x0000, data_types.Uint8.ID, 0 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.movement_control.back.down()))
    end
)

test.register_coroutine_test(
    "Device reported back 1 and driver emit movement_control.back.up()",
    function()
        local attr_report_data = {
            { 0x0000, data_types.Uint8.ID, 1 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.movement_control.back.up()))
    end
)

test.register_coroutine_test(
    "Device reported leg 0 and driver emit movement_control.leg.down()",
    function()
        local attr_report_data = {
            { 0x0001, data_types.Uint8.ID, 0 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.movement_control.leg.down()))
    end
)

test.register_coroutine_test(
    "Device reported leg 1 and driver emit movement_control.leg.up()",
    function()
        local attr_report_data = {
            { 0x0001, data_types.Uint8.ID, 1 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.movement_control.leg.up()))
    end
)

test.register_coroutine_test(
    "Device reported backLeg 0 and driver emit movement_control.backLeg.down()",
    function()
        local attr_report_data = {
            { 0x0001, data_types.Uint8.ID, 0 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.movement_control.backLeg.down()))
    end
)

test.register_coroutine_test(
    "Device reported backLeg 1 and driver emit movement_control.backLeg.up()",
    function()
        local attr_report_data = {
            { 0x0001, data_types.Uint8.ID, 1 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.movement_control.backLeg.up()))
    end
)

test.register_coroutine_test(
    "Device reported back_massage 0 and driver emit .massage_control.backStrength(0)",
    function()
        local attr_report_data = {
            { 0x0003, data_types.Uint8.ID, 0 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.backStrength(0)))
    end
)

test.register_coroutine_test(
    "Device reported back_massage 1 and driver emit .massage_control.backStrength(1)",
    function()
        local attr_report_data = {
            { 0x0003, data_types.Uint8.ID, 1 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.backStrength(1)))
    end
)

test.register_coroutine_test(
    "Device reported back_massage 2 and driver emit .massage_control.backStrength(2)",
    function()
        local attr_report_data = {
            { 0x0003, data_types.Uint8.ID, 2 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.backStrength(2)))
    end
)

test.register_coroutine_test(
    "Device reported back_massage 3 and driver emit .massage_control.backStrength(3)",
    function()
        local attr_report_data = {
            { 0x0003, data_types.Uint8.ID, 3 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.backStrength(3)))
    end
)

test.register_coroutine_test(
    "Device reported leg_massage 0 and driver emit .massage_control.legStrength(0)",
    function()
        local attr_report_data = {
            { 0x0004, data_types.Uint8.ID, 0 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.legStrength(0)))
    end
)

test.register_coroutine_test(
    "Device reported leg_massage 1 and driver emit .massage_control.legStrength(1)",
    function()
        local attr_report_data = {
            { 0x0004, data_types.Uint8.ID, 1 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.legStrength(1)))
    end
)

test.register_coroutine_test(
    "Device reported leg_massage 2 and driver emit .massage_control.legStrength(2)",
    function()
        local attr_report_data = {
            { 0x0004, data_types.Uint8.ID, 2 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.legStrength(2)))
    end
)

test.register_coroutine_test(
    "Device reported leg_massage 3 and driver emit .massage_control.legStrength(3)",
    function()
        local attr_report_data = {
            { 0x0004, data_types.Uint8.ID, 3 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.legStrength(3)))
    end
)

test.register_coroutine_test(
    "Device reported massage_frequency 0 and driver emit .massage_control.frequency(1)",
    function()
        local attr_report_data = {
            { 0x0005, data_types.Uint8.ID, 0 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.frequency(1)))
    end
)

test.register_coroutine_test(
    "Device reported massage_frequency 1 and driver emit .massage_control.frequency(2)",
    function()
        local attr_report_data = {
            { 0x0005, data_types.Uint8.ID, 1 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.frequency(2)))
    end
)

test.register_coroutine_test(
    "Device reported massage_frequency 2 and driver emit .massage_control.frequency(3)",
    function()
        local attr_report_data = {
            { 0x0005, data_types.Uint8.ID, 2 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.frequency(3)))
    end
)

test.register_coroutine_test(
    "Device reported massage_frequency 3 and driver emit .massage_control.frequency(4)",
    function()
        local attr_report_data = {
            { 0x0005, data_types.Uint8.ID, 3 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.frequency(4)))
    end
)

test.register_coroutine_test(
    "Device reported massage_switch 0 and driver emit .massage_control.state(off)",
    function()
        local attr_report_data = {
            { 0x0006, data_types.Uint8.ID, 0 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.state("off")))
    end
)

test.register_coroutine_test(
    "Device reported massage_switch 1 and driver emit .massage_control.state(10M)",
    function()
        local attr_report_data = {
            { 0x0006, data_types.Uint8.ID, 1 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.state("10M")))
    end
)

test.register_coroutine_test(
    "Device reported massage_switch 2 and driver emit .massage_control.state(20M)",
    function()
        local attr_report_data = {
            { 0x0006, data_types.Uint8.ID, 2 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.state("20M")))
    end
)

test.register_coroutine_test(
    "Device reported massage_switch 3 and driver emit .massage_control.state(30M)",
    function()
        local attr_report_data = {
            { 0x0006, data_types.Uint8.ID, 3 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.state("30M")))
    end
)

test.register_coroutine_test(
    "Device reported mode 0 and driver emit custom_capabilities.mode.state(stop)",
    function()
        local attr_report_data = {
            { 0x000b, data_types.Uint8.ID, 0 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.state("stop")))
    end
)

test.register_coroutine_test(
    "Device reported mode 1 and driver emit custom_capabilities.mode.state(zeroGravity)",
    function()
        local attr_report_data = {
            { 0x000b, data_types.Uint8.ID, 1 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.state("zeroGravity")))
    end
)

test.register_coroutine_test(
    "Device reported mode 2 and driver emit custom_capabilities.mode.state(leisure)",
    function()
        local attr_report_data = {
            { 0x000b, data_types.Uint8.ID, 2 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.state("leisure")))
    end
)

test.register_coroutine_test(
    "Device reported mode 3 and driver emit custom_capabilities.mode.state(snoringIntervention)",
    function()
        local attr_report_data = {
            { 0x000b, data_types.Uint8.ID, 3 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.state("snoringIntervention")))
    end
)

test.register_coroutine_test(
    "Device reported mode 4 and driver emit custom_capabilities.mode.state(reading)",
    function()
        local attr_report_data = {
            { 0x000b, data_types.Uint8.ID, 4 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.state("reading")))
    end
)

test.register_coroutine_test(
    "Device reported mode 5 and driver emit custom_capabilities.mode.state(lyingFlat)",
    function()
        local attr_report_data = {
            { 0x000b, data_types.Uint8.ID, 5 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.state("lyingFlat")))
    end
)

test.register_coroutine_test(
    "Device reported mode 6 and driver emit custom_capabilities.mode.state(comfort)",
    function()
        local attr_report_data = {
            { 0x000b, data_types.Uint8.ID, 6 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.massage_control.state("comfort")))
    end
)

test.register_coroutine_test(
    "Device reported night_light 0 and driver emit custom_capabilities.night_light.state(off)",
    function()
        local attr_report_data = {
            { 0x000c, data_types.Uint8.ID, 0 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.night_light.state("off")))
    end
)

test.register_coroutine_test(
    "Device reported night_light 1 and driver emit custom_capabilities.night_light.state(10M)",
    function()
        local attr_report_data = {
            { 0x000c, data_types.Uint8.ID, 1 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.night_light.state("10M")))
    end
)

test.register_coroutine_test(
    "Device reported night_light 2 and driver emit custom_capabilities.night_light.state(8H)",
    function()
        local attr_report_data = {
            { 0x000c, data_types.Uint8.ID, 2 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.night_light.state("8H")))
    end
)

test.register_coroutine_test(
    "Device reported night_light 2 and driver emit custom_capabilities.night_light.state(10H)",
    function()
        local attr_report_data = {
            { 0x000c, data_types.Uint8.ID, 2 }
        }
        test.socket.zigbee:__queue_receive({
            mock_device.id,
            zigbee_test_utils.build_attribute_report(mock_device, PRIVATE_CLUSTER_ID, attr_report_data, MFG_CODE)
        })
        test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            custom_capabilities.night_light.state("10H")))
    end
)

test.register_coroutine_test(
    "capability backControl up and driver zigbee send 0 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.movement_control.ID, component = "main", command ="backControl" , args = {"up"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0000, MFG_CODE, data_types.Uint8, 0)
        })
    end
)

test.register_coroutine_test(
    "capability backControl down and driver zigbee send 1 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.movement_control.ID, component = "main", command ="backControl" , args = {"down"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0000, MFG_CODE, data_types.Uint8, 1)
        })
    end
)

test.register_coroutine_test(
    "capability legControl up and driver zigbee send 0 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.movement_control.ID, component = "main", command ="legControl" , args = {"up"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0001, MFG_CODE, data_types.Uint8, 0)
        })
    end
)

test.register_coroutine_test(
    "capability legControl down and driver zigbee send 1 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.movement_control.ID, component = "main", command ="legControl" , args = {"down"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0001, MFG_CODE, data_types.Uint8, 1)
        })
    end
)

test.register_coroutine_test(
    "capability backLegControl up and driver zigbee send 0 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.movement_control.ID, component = "main", command ="backLegControl" , args = {"up"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0002, MFG_CODE, data_types.Uint8, 0)
        })
    end
)

test.register_coroutine_test(
    "capability backLegControl down and driver zigbee send 1 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.movement_control.ID, component = "main", command ="backLegControl" , args = {"down"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0002, MFG_CODE, data_types.Uint8, 1)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control stateControl off and driver zigbee send 0 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="stateControl" , args = {"off"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0006, MFG_CODE, data_types.Uint8, 0)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control stateControl 10M and driver zigbee send 1 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="stateControl" , args = {"10M"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0006, MFG_CODE, data_types.Uint8, 1)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control stateControl 20M and driver zigbee send 2 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="stateControl" , args = {"20M"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0006, MFG_CODE, data_types.Uint8, 2)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control stateControl 30M and driver zigbee send 3 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="stateControl" , args = {"30M"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0006, MFG_CODE, data_types.Uint8, 3)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control backStrengthControl 0 and driver zigbee send 0 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="backStrengthControl" , args = {0}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0003, MFG_CODE, data_types.Uint8, 0)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control backStrengthControl 1 and driver zigbee send 1 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="backStrengthControl" , args = {1}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0003, MFG_CODE, data_types.Uint8, 1)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control backStrengthControl 2 and driver zigbee send 2 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="backStrengthControl" , args = {2}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0003, MFG_CODE, data_types.Uint8, 2)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control backStrengthControl 3 and driver zigbee send 3 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="backStrengthControl" , args = {3}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0003, MFG_CODE, data_types.Uint8, 3)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control legStrengthControl 0 and driver zigbee send 0 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="legStrengthControl" , args = {0}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0004, MFG_CODE, data_types.Uint8, 0)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control legStrengthControl 1 and driver zigbee send 1 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="legStrengthControl" , args = {1}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0004, MFG_CODE, data_types.Uint8, 1)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control legStrengthControl 2 and driver zigbee send 2 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="legStrengthControl" , args = {2}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0004, MFG_CODE, data_types.Uint8, 2)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control legStrengthControl 3 and driver zigbee send 3 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="legStrengthControl" , args = {3}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0004, MFG_CODE, data_types.Uint8, 3)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control frequencyControl 1 and driver zigbee send 0 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="frequencyControl" , args = {1}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0005, MFG_CODE, data_types.Uint8, 0)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control frequencyControl 2 and driver zigbee send 1 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="frequencyControl" , args = {2}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0005, MFG_CODE, data_types.Uint8, 1)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control frequencyControl 3 and driver zigbee send 2 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="frequencyControl" , args = {3}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0005, MFG_CODE, data_types.Uint8, 2)
        })
    end
)

test.register_coroutine_test(
    "capability massage_control frequencyControl 4 and driver zigbee send 3 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.massage_control.ID, component = "main", command ="frequencyControl" , args = {4}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x0005, MFG_CODE, data_types.Uint8, 3)
        })
    end
)

test.register_coroutine_test(
    "capability mode stateControl stop and driver zigbee send 0 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.mode.ID, component = "main", command ="stateControl" , args = {"stop"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x000b, MFG_CODE, data_types.Uint8, 0)
        })
    end
)

test.register_coroutine_test(
    "capability mode stateControl zeroGravity and driver zigbee send 1 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.mode.ID, component = "main", command ="stateControl" , args = {"zeroGravity"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x000b, MFG_CODE, data_types.Uint8, 1)
        })
    end
)

test.register_coroutine_test(
    "capability mode stateControl leisure and driver zigbee send 2 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.mode.ID, component = "main", command ="stateControl" , args = {"leisure"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x000b, MFG_CODE, data_types.Uint8, 2)
        })
    end
)

test.register_coroutine_test(
    "capability mode stateControl snoringIntervention and driver zigbee send 3 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.mode.ID, component = "main", command ="stateControl" , args = {"snoringIntervention"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x000b, MFG_CODE, data_types.Uint8, 3)
        })
    end
)

test.register_coroutine_test(
    "capability mode stateControl reading and driver zigbee send 4 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.mode.ID, component = "main", command ="stateControl" , args = {"reading"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x000b, MFG_CODE, data_types.Uint8, 4)
        })
    end
)

test.register_coroutine_test(
    "capability mode stateControl lyingFlat and driver zigbee send 5 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.mode.ID, component = "main", command ="stateControl" , args = {"lyingFlat"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x000b, MFG_CODE, data_types.Uint8, 5)
        })
    end
)

test.register_coroutine_test(
    "capability mode stateControl comfort and driver zigbee send 6 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.mode.ID, component = "main", command ="stateControl" , args = {"comfort"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x000b, MFG_CODE, data_types.Uint8, 6)
        })
    end
)

test.register_coroutine_test(
    "capability night_light stateControl off and driver zigbee send 0 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.night_light.ID, component = "main", command ="stateControl" , args = {"off"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x000c, MFG_CODE, data_types.Uint8, 0)
        })
    end
)

test.register_coroutine_test(
    "capability night_light stateControl 10M and driver zigbee send 1 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.night_light.ID, component = "main", command ="stateControl" , args = {"10M"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x000c, MFG_CODE, data_types.Uint8, 1)
        })
    end
)

test.register_coroutine_test(
    "capability night_light stateControl 8H and driver zigbee send 2 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.night_light.ID, component = "main", command ="stateControl" , args = {"8H"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x000c, MFG_CODE, data_types.Uint8, 2)
        })
    end
)

test.register_coroutine_test(
    "capability night_light stateControl 10H and driver zigbee send 3 ",
    function()
        test.socket.capability:__queue_receive({
            mock_device.id,
            { capability = custom_capabilities.night_light.ID, component = "main", command ="stateControl" , args = {"10H"}}
        })
        test.socket.zigbee:__expect_send({ mock_device.id,
            cluster_base.write_manufacturer_specific_attribute(mock_device, PRIVATE_CLUSTER_ID,
            0x000c, MFG_CODE, data_types.Uint8, 3)
        })
    end
)

test.run_registered_tests()
