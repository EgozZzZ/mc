package dev.axiom.module.modules.visual;
import dev.axiom.AxiomClient;
import dev.axiom.module.Category;
import dev.axiom.module.Module;
import dev.axiom.setting.*;
import net.fabricmc.fabric.api.client.rendering.v1.HudRenderCallback;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.render.RenderTickCounter;
import net.minecraft.text.Text;
import java.awt.Color;
import java.util.*;
import java.util.stream.Collectors;
public class HUD extends Module {
    public final BooleanSetting arrayList   = register(new BooleanSetting("ArrayList",   true));
    public final BooleanSetting watermark   = register(new BooleanSetting("Watermark",   true));
    public final BooleanSetting coords      = register(new BooleanSetting("Coords",      true));
    public final BooleanSetting fps         = register(new BooleanSetting("FPS",         true));
    public final ModeSetting    colorMode   = register(new ModeSetting("Color Mode","Rainbow","Rainbow","Static","Fade"));
    public final NumberSetting  rainbowSpeed= register(new NumberSetting("Rainbow Speed",2.0,0.1,10));
    public HUD() { super("HUD","Vibecoded heads-up display",Category.VISUAL,-1); }
    @Override protected void onEnable() { HudRenderCallback.EVENT.register(this::onHudRender); }
    private void onHudRender(DrawContext ctx, RenderTickCounter counter) {
        if (mc.player==null) return;
        int screenW=mc.getWindow().getScaledWidth(); int y=2;
        if (watermark.getValue()) { ctx.drawTextWithShadow(mc.textRenderer,Text.of("§b§lAxiom §7§lClient"),2,y,0xFFFFFF); y+=10; }
        if (fps.getValue()) { ctx.drawTextWithShadow(mc.textRenderer,Text.of("§7FPS: §f"+mc.getCurrentFps()),2,y,0xFFFFFF); y+=10; }
        if (coords.getValue()) ctx.drawTextWithShadow(mc.textRenderer,Text.of(String.format("§7XYZ: §f%.0f §f%.0f §f%.0f",mc.player.getX(),mc.player.getY(),mc.player.getZ())),2,y,0xFFFFFF);
        if (arrayList.getValue()) {
            List<Module> enabled=AxiomClient.MODULE_MANAGER.getModules().stream().filter(Module::isEnabled).sorted(Comparator.comparing(m->m.name)).collect(Collectors.toList());
            int ay=2;
            for (int i=0;i<enabled.size();i++) {
                Module m=enabled.get(i); int color=getRainbowColor(i);
                int textW=mc.textRenderer.getWidth(m.name);
                ctx.drawTextWithShadow(mc.textRenderer,Text.of(m.name),screenW-textW-2,ay,color); ay+=10;
            }
        }
    }
    private int getRainbowColor(int index) {
        if (colorMode.getValue().equals("Static")) return 0x00BFFF;
        float hue=((System.currentTimeMillis()*rainbowSpeed.getValue()/5000f)+(index*0.1f))%1.0f;
        return Color.HSBtoRGB(hue,0.8f,1.0f);
    }
}
