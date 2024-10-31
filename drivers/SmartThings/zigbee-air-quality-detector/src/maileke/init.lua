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

local clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"
local device_management = require "st.zigbee.device_management"
local custom_clusters = require "maileke/custom_clusters"
local log = require "log"

local IlluminanceMeasurement = clusters.IlluminanceMeasurement
local RelativeHumidity = clusters.RelativeHumidity
local TemperatureMeasurement = clusters.TemperatureMeasurement



local PowerConfiguration = clusters.PowerConfiguration

local MAILEKE_SENSOR_FINGERPRINTS = {
  { mfr = "MAILEKE", model = "air" }
}

local function can_handle_maileke_sensor(opts, driver, device)
  for _, fingerprint in ipairs(MAILEKE_SENSOR_FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      return true
    end
  end
  return false
end

local function do_refresh(driver, device)
  device:send(RelativeHumidity.attributes.MeasuredValue:read(device):to_endpoint(0x01))
  device:send(TemperatureMeasurement.attributes.MeasuredValue:read(device))
  device:send(PowerConfiguration.attributes.BatteryPercentageRemaining:read(device))
end

local function do_configure(driver, device)
  device:send(device_management.build_bind_request(device, RelativeHumidity.ID, driver.environment_info.hub_zigbee_eui):to_endpoint(0x01))
  device:configure()
  device:send(RelativeHumidity.attributes.MeasuredValue:configure_reporting(device, 30, 3600, 100):to_endpoint(0x01))
  do_refresh(driver, device)
end

local units = {
  PPM = 0,
  PPB = 1,
  PPT = 2,
  MGM3 = 3,
  UGM3 = 4,
  NGM3 = 5,
  PM3 = 6,
  BQM3 = 7,
  PCIL = 0xFF
}

local unit_strings = {
  [units.PPM] = "ppm",
  [units.PPB] = "ppb",
  [units.PPT] = "ppt",
  [units.MGM3] = "mg/m^3",
  [units.NGM3] = "ng/m^3",
  [units.UGM3] = "μg/m^3",
  [units.BQM3] = "Bq/m^3",
  [units.PCIL] = "pCi/L"
}

local function carbonDioxide_attr_handler()
  return function(driver, device, value, zb_rx)
  log.error("carbonDioxide_attr_handler " )
    --device:emit_event_for_endpoint(device.fingerprinted_endpoint_id, capabilities.dustSensor.fineDustLevel({value = value, unit = unit_strings[target_unit]}))
    device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, capabilities.carbonDioxideMeasurement.carbonDioxide({value = value}))
  end
end

local function measurementHandlerFactory(capability, t_unit)
  return function(driver, device, value, zb_rx)
  log.error("measurementHandlerFactory " )
	--[[if capability.NAME == capabilities.relativeHumidityMeasurement.humidity.NAME then
       device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, capability({value = value}))
	else
	   device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, capability({value = value, unit = t_unit}))
	end--]]
  end
end

local function pm2_5_attr_handler(cap)
  return function(driver, device, value, zb_rx)
  log.error("pm2_5_attr_handler " )
   --[[ if cap.NAME == capabilities.fineDustSensor.fineDustLevel.NAME then
      device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, cap({value = value, unit = unit_strings[units.MGM3]}))
    elseif cap.NAME == capabilities.dustSensor.fineDustLevel.NAME then
      device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, cap({value = value, unit = unit_strings[units.MGM3]}))
    elseif cap.NAME == capabilities.veryFineDustSensor.veryFineDustLevel.NAME then
      device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, cap({value = value, unit = unit_strings[units.MGM3]}))
    end --]]
  end
end

local function CH2O_attr_handler(cap)
  return function(driver, device, value, zb_rx)
  log.error("CH2O_attr_handler " )
  if cap.NAME == capabilities.formaldehydeMeasurement.formaldehydeLevel.NAME then
    device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, cap({value = value, unit = unit_strings[units.MGM3]}))
  elseif cap.NAME == capabilities.tvocMeasurement.tvocLevel.NAME then
    device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, cap({value = value, unit = unit_strings[units.MGM3]}))
  end
  end
end

local maileke_sensor = {
  NAME = "maileke air quality detector",
  lifecycle_handlers = {
    doConfigure = do_configure
  },
  zigbee_handlers = {
    attr = {
--[[	  [clusters.TemperatureMeasurement.ID] = {
        [clusters.TemperatureMeasurement.attributes.MeasuredValue.ID] = measurementHandlerFactory(capabilities.temperatureMeasurement.temperature,"C")
      },
	  [clusters.RelativeHumidity.ID] = {
        [clusters.RelativeHumidity.attributes.MeasuredValue.ID] = measurementHandlerFactory(capabilities.relativeHumidityMeasurement.humidity,"null")
      },
	  [clusters.IlluminanceMeasurement.ID] = {
        [clusters.IlluminanceMeasurement.attributes.MeasuredValue.ID] = measurementHandlerFactory(capabilities.illuminanceMeasurement.illuminance,"lux")
      },
	  --]]
      [custom_clusters.carbonDioxide.id] = {
        [custom_clusters.carbonDioxide.attributes.measured_value.id] = carbonDioxide_attr_handler()
      },
	  [custom_clusters.pm2_5.id] = {
        [custom_clusters.pm2_5.attributes.pm2_5.id] = pm2_5_attr_handler(capabilities.fineDustSensor.fineDustLevel),
        [custom_clusters.pm2_5.attributes.pm1_0.id] = pm2_5_attr_handler(capabilities.dustSensor.fineDustLevel),
        [custom_clusters.pm2_5.attributes.pm10.id] = pm2_5_attr_handler(capabilities.veryFineDustSensor.veryFineDustLevel)
      },
	  [custom_clusters.CH2O.id] = {
        [custom_clusters.CH2O.attributes.CH2O.id] = CH2O_attr_handler(capabilities.formaldehydeMeasurement.formaldehydeLevel),
        [custom_clusters.CH2O.attributes.tvoc.id] = CH2O_attr_handler(capabilities.tvocMeasurement.tvocLevel)
      }
    }
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = do_refresh,
    }
  },
  can_handle = can_handle_maileke_sensor
}

return maileke_sensor
