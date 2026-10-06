package dev.axiom.module;
import dev.axiom.AxiomClient;
import dev.axiom.setting.Setting;
import net.minecraft.client.MinecraftClient;
import java.util.ArrayList;
import java.util.List;
public abstract class Module {
    protected static final MinecraftClient mc = MinecraftClient.getInstance();
    public final String name, description;
    public final Category category;
    public int keybind;
    private boolean enabled;
    protected final List<Setting<?>> settings = new ArrayList<>();
    public Module(String name, String description, Category category, int keybind) {
        this.name = name; this.description = description;
        this.category = category; this.keybind = keybind;
    }
    public void toggle() { setEnabled(!enabled); }
    public void setEnabled(boolean state) {
        this.enabled = state;
        if (state) { AxiomClient.EVENT_BUS.subscribe(this); onEnable(); }
        else { AxiomClient.EVENT_BUS.unsubscribe(this); onDisable(); }
    }
    public boolean isEnabled() { return enabled; }
    protected void onEnable() {}
    protected void onDisable() {}
    protected <T extends Setting<?>> T register(T s) { settings.add(s); return s; }
    public List<Setting<?>> getSettings() { return settings; }
}
