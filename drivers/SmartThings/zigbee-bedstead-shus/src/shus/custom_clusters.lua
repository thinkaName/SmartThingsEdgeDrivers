-- Copyright 2024 SmartThings
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

local data_types = require "st.zigbee.data_types"

local custom_clusters = {
  shus_smart_bedstead = {
    id = 0xFCC1,
    mfg_specific_code = 0x1235,
    attributes = {
      back_control = {
        id = 0x0000,
        value_type = data_types.Uint8,
        value = {
          up = 0,
          down = 1
        }
      },
      leg_control = {
        id = 0x0001,
        value_type = data_types.Uint8,
        value = {
          up = 0,
          down = 1
        }
      },
      back_leg_control = {
        id = 0x0002,
        value_type = data_types.Uint8,
        value = {
          up = 0,
          down = 1
        }
      },
      back_massage = {
        id = 0x0003,
        value_type = data_types.Uint8,
        value = {}
      },
      leg_massage = {
        id = 0x0004,
        value_type = data_types.Uint8,
        value = {}
      },
      massage_frequency = {
        id = 0x0005,
        value_type = data_types.Uint8,
        value = {}
      },
      massage_switch = {
        id = 0x0006,
        value_type = data_types.Uint8,
        value = {
          off = 0,
          m_10 = 1,
          m_20 = 2,
          m_30 = 3
        }
      },
      mode = {
        id = 0x000B,
        value_type = data_types.Uint8,
        value = {
          stop = 0,
          zero_gravity = 1,
          leisure = 2,
          snoring_intervention = 3,
          reading = 4,
          lying_flat = 5,
          comfort = 6
        }
      },
      night_light = {
        id = 0x000C,
        value_type = data_types.Uint8,
        value = {
          off = 0,
          m_10 = 1,
          h_8 = 2,
          h_10 = 3
        }
      }
    }
  }
}

return custom_clusters
