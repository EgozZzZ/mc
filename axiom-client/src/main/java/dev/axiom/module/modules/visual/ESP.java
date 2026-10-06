package dev.axiom.module.modules.visual;
import dev.axiom.event.Subscribe;
import dev.axiom.event.events.EventRender3D;
import dev.axiom.module.Category;
import dev.axiom.module.Module;
import dev.axiom.setting.*;
import dev.axiom.util.RenderUtil;
import net.minecraft.entity.decoration.EndCrystalEntity;
import net.minecraft.entity.player.PlayerEntity;
public class ESP extends Module {
    public final BooleanSetting players    = register(new BooleanSetting("Players",    true));
    public final BooleanSetting crystals   = register(new BooleanSetting("Crystals",   true));
    public final BooleanSetting tracers    = register(new BooleanSetting("Tracers",    false));
    public final BooleanSetting healthBars = register(new BooleanSetting("Health Bars",true));
    public ESP() { super("ESP","Entity box and tracer ESP",Category.VISUAL,-1); }
    @Subscribe public void onRender3D(EventRender3D event) {
        if (mc.world==null||mc.player==null) return;
        for (var entity:mc.world.getEntities()) {
            if (entity==mc.player) continue;
            if (players.getValue()&&entity instanceof PlayerEntity player) {
                RenderUtil.drawBox(event.matrices,player.getBoundingBox(),0x4400BFFF,0xFF00BFFF);
                if (tracers.getValue()) RenderUtil.drawTracer(event.matrices,player.getPos(),0xFF00FF88);
            }
            if (crystals.getValue()&&entity instanceof EndCrystalEntity crystal)
                RenderUtil.drawBox(event.matrices,crystal.getBoundingBox(),0x44FF6600,0xFFFF6600);
        }
    }
}
