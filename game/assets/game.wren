import "core" for Data, DataTarget

class Game {
    static config() {
        Data.setString("Title", "Guantlet", DataTarget.system)
        Data.setInt("Width", 800, DataTarget.system)
        Data.setInt("Height", 600, DataTarget.system)
        Data.setBool("Fullscreen", false, DataTarget.system)
    }
    
    static init() {
    }

    static update() {
    }

    static render() {
    }
}