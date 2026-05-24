local dev = os.getenv("dev") and "_dev" or ""

require("SpeedMod")
require("TeleportMod")
require("TileCaptureRT" .. dev)
-- require("StatsMod")
-- require("TileCaptureHRS")
require("ToggleEffects")
