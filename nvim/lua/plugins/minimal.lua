-- Product exclusions are generated from the reviewed policy registry so the
-- runtime spec, rationale, validation, and lock normalization cannot drift.
return require("config.product_policy").plugin_exclusion_specs()
