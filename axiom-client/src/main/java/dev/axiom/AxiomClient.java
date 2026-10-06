package dev.axiom;
import dev.axiom.event.EventBus;
import dev.axiom.module.ModuleManager;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.util.InputUtil;
import org.lwjgl.glfw.GLFW;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
public class AxiomClient implements ClientModInitializer {
    public static final String NAME = "Axiom";
    public static final String VERSION = "1.0.0";
    public static final Logger LOGGER = LoggerFactory.getLogger(NAME);
    public static final MinecraftClient mc = MinecraftClient.getInstance();
    public static AxiomClient INSTANCE;
    public static EventBus EVENT_BUS;
    public static ModuleManager MODULE_MANAGER;
    public static KeyBinding GUI_KEY;
    @Override
    public void onInitializeClient() {
        INSTANCE = this;
        EVENT_BUS = new EventBus();
        MODULE_MANAGER = new ModuleManager();
        MODULE_MANAGER.init();
        GUI_KEY = KeyBindingHelper.registerKeyBinding(new KeyBinding(
            "key.axiomclient.open_gui", InputUtil.Type.KEYSYM,
            GLFW.GLFW_KEY_RIGHT_SHIFT, "Axiom Client"
        ));
        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            while (GUI_KEY.wasPressed()) {
                if (client.currentScreen == null)
                    client.setScreen(new dev.axiom.gui.clicks.AxiomGUIScreen());
            }
        });
        LOGGER.info("[Axiom] {} modules loaded.", MODULE_MANAGER.getModules().size());
    }
}
