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

-- Mock out globals
local test = require "integration_test"
local clusters = require "st.zigbee.zcl.clusters"
local IASZone = clusters.IASZone
local PowerConfiguration = clusters.PowerConfiguration
local capabilities = require "st.capabilities"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local IasEnrollResponseCode = require "st.zigbee.generated.zcl_clusters.IASZone.types.EnrollResponseCode"
local t_utils = require "integration_test.utils"
local cluster_base = require "st.zigbee.cluster_base"


local profile_def = t_utils.get_profile_definition("shus-smart-mattress.yml")
local MFG_CODE = 0x1235

local mock_device = test.mock_device.build_test_zigbee_device(
{
  label = "air quality detector",
  profile = profile_def,
  zigbee_endpoints = {
    [1] = {
      id = 1,
      manufacturer = "SHUS",
      model = "SX-1",
      server_clusters = { 0x0000, 0x0400, 0x0402, 0x0405, 0x040D, 0x042A, 0x042B}
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
  "capability - refresh",
  function()
    test.socket.capability:__queue_receive({ mock_device.id,
      { capability = "refresh", component = "main", command = "refresh", args = {} } })
    local read_RelativeHumidity_messge = cluster_base.read_attribute(mock_device, clusters.RelativeHumidity.id, clusters.RelativeHumidity.attributes.MeasuredValue)
	local read_TemperatureMeasurement_messge = cluster_base.read_attribute(mock_device, clusters.TemperatureMeasurement.id, clusters.TemperatureMeasurement.attributes.MeasuredValue)
	local read_PowerConfiguration_messge = cluster_base.read_attribute(mock_device, clusters.PowerConfiguration.id, clusters.PowerConfiguration.attributes.BatteryPercentageRemaining)
    local read_pm2_5_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, 0x042A, 0x0000, MFG_CODE)
    local read_pm1_0_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, 0x042A, 0x0001, MFG_CODE)
    local read_pm10_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, 0x042A, 0x0002, MFG_CODE)
	local read_ch2o_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, 0x042B, 0x0000, MFG_CODE)
	local read_tvoc_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, 0x042B, 0x0001, MFG_CODE)
    local read_carbonDioxide_messge = cluster_base.read_manufacturer_specific_attribute(mock_device, 0x040D, 0x0000, MFG_CODE)

    test.socket.zigbee:__expect_send({mock_device.id, read_RelativeHumidity_messge})
    test.socket.zigbee:__expect_send({mock_device.id, read_TemperatureMeasurement_messge})
    test.socket.zigbee:__expect_send({mock_device.id, read_PowerConfiguration_messge})
    test.socket.zigbee:__expect_send({mock_device.id, read_pm2_5_messge})
    test.socket.zigbee:__expect_send({mock_device.id, read_pm1_0_messge})
    test.socket.zigbee:__expect_send({mock_device.id, read_pm10_messge})
    test.socket.zigbee:__expect_send({mock_device.id, read_ch2o_messge})
    test.socket.zigbee:__expect_send({mock_device.id, read_tvoc_messge})
    test.socket.zigbee:__expect_send({mock_device.id, read_carbonDioxide_messge})
  end
)

test.register_coroutine_test(
  "Device reported carbonDioxide and driver emit carbonDioxide and carbonDioxideHealthConcern",
  function()
    local attr_report_data = {
      { 0x0000, data_types.SinglePrecisionFloat.ID, 1400 }
    }
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      zigbee_test_utils.build_attribute_report(mock_device, 0x040D, attr_report_data, MFG_CODE)
    })
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
      capabilities.carbonDioxideMeasurement.carbonDioxide({value = 74, unit = "ppm"})))
	  
	test.socket.capability:__expect_send(mock_device:generate_test_message("main",
      capabilities.carbonDioxideHealthConcern.carbonDioxideHealthConcern({value = "good"})))
  end
)

test.register_coroutine_test(
  "Device reported pm2.5 and driver emit pm2.5 and fineDustHealthConcern",
  function()
    local attr_report_data = {
      { 0x0000, data_types.Uint16.ID, 74 }
    }
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      zigbee_test_utils.build_attribute_report(mock_device, 0x042A, attr_report_data, MFG_CODE)
    })
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
      capabilities.fineDustSensor.fineDustLevel({value = 74 })))
	  
	test.socket.capability:__expect_send(mock_device:generate_test_message("main",
      capabilities.fineDustHealthConcern.fineDustHealthConcern({value = "good"})))
  end
)

test.register_coroutine_test(
  "Device reported pm1.0 and driver emit pm1.0 and veryFineDustHealthConcern",
  function()
    local attr_report_data = {
      { 0x0000, data_types.Uint16.ID, 74 }
    }
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      zigbee_test_utils.build_attribute_report(mock_device, 0x042A, attr_report_data, MFG_CODE)
    })
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
      capabilities.veryFineDustSensor.veryFineDustLevel({value = 70 })))
	  
	test.socket.capability:__expect_send(mock_device:generate_test_message("main",
      capabilities.veryFineDustHealthConcern.veryFineDustHealthConcern({value = "good"})))
  end
)

test.run_registered_tests()
