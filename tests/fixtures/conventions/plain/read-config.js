import fs from "fs";
import path from "path";

export function readConfig(name) {
    const file = path.join("config", name);
    return fs.readFileSync(file, "utf8");
}
