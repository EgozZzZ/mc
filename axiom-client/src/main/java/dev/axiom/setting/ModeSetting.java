package dev.axiom.setting;
import java.util.List;
public class ModeSetting extends Setting<String> {
    public final List<String> modes;
    public ModeSetting(String name, String defaultMode, String... modes) {
        super(name, defaultMode); this.modes = List.of(modes);
    }
    public void cycle() {
        int idx = modes.indexOf(value);
        value = modes.get((idx + 1) % modes.size());
    }
}
