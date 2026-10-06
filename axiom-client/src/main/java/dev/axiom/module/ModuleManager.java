package dev.axiom.module;
import dev.axiom.module.modules.combat.*;
import dev.axiom.module.modules.visual.*;
import java.util.ArrayList;
import java.util.List;
public class ModuleManager {
    private final List<Module> modules = new ArrayList<>();
    public void init() {
        register(new AutoCrystal());
        register(new AutoMace());
        register(new CrystalOptimiser());
        register(new ESP());
        register(new HUD());
        register(new ClickGUI());
        register(new Cosmetics());
    }
    private void register(Module m) { modules.add(m); }
    public List<Module> getModules() { return modules; }
    public <T extends Module> T get(Class<T> clazz) {
        return modules.stream().filter(m -> m.getClass() == clazz)
                .map(clazz::cast).findFirst().orElse(null);
    }
    public Module getByName(String name) {
        return modules.stream().filter(m -> m.name.equalsIgnoreCase(name))
                .findFirst().orElse(null);
    }
}
