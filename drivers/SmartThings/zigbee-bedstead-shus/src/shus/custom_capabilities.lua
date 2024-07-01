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

local capabilities = require "st.capabilities"

local custom_capabilities = {
    movement_control = capabilities["absolutegreen57841.movementControl"],
    massage_control = capabilities["absolutegreen57841.massageControl"],
    mode = capabilities["absolutegreen57841.mode"],
    night_light = capabilities["absolutegreen57841.nightLight"]
}

return custom_capabilities
