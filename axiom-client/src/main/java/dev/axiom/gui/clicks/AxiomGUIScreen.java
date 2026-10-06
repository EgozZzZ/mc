package dev.axiom.gui.clicks;
import dev.axiom.AxiomClient;
import dev.axiom.module.Module;
import dev.axiom.module.Category;
import dev.axiom.setting.*;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.text.Text;
import java.util.*;
import java.util.stream.Collectors;
public class AxiomGUIScreen extends Screen {
    private Category selectedCategory=Category.COMBAT;
    private Module selectedModule=null;
    private static final int SIDEBAR_W=110,MODULE_W=160,SETTING_W=200,ROW_H=20,PADDING=6;
    private Setting<?> dragging=null; private double dragStartX=0,dragStartVal=0;
    public AxiomGUIScreen(){ super(Text.of("Axiom")); }
    @Override public void render(DrawContext ctx,int mx,int my,float delta){
        ctx.fillGradient(0,0,width,height,0xCC0A0A14,0xCC0A0A14);
        renderSidebar(ctx,mx,my); renderModuleList(ctx,mx,my);
        if(selectedModule!=null) renderSettings(ctx,mx,my);
        ctx.drawTextWithShadow(client.textRenderer,Text.of("§b§lAxiom §8| §7Settings"),PADDING,PADDING,0xFFFFFF);
    }
    private void renderSidebar(DrawContext ctx,int mx,int my){
        int x=PADDING,y=24;
        for(Category cat:Category.values()){
            boolean sel=cat==selectedCategory;
            ctx.fill(x,y,x+SIDEBAR_W,y+ROW_H,sel?0xFF1E3A5F:0xFF111827);
            if(sel) ctx.fill(x,y,x+3,y+ROW_H,0xFF00BFFF);
            ctx.drawTextWithShadow(client.textRenderer,Text.of(cat.name()),x+8,y+6,sel?0xFF00BFFF:0xFF8899AA);
            y+=ROW_H+2;
        }
    }
    private void renderModuleList(DrawContext ctx,int mx,int my){
        int x=PADDING+SIDEBAR_W+4,y=24;
        for(Module m:AxiomClient.MODULE_MANAGER.getModules().stream().filter(mod->mod.category==selectedCategory).collect(Collectors.toList())){
            boolean sel=m==selectedModule;
            ctx.fill(x,y,x+MODULE_W,y+ROW_H,sel?0xFF1A2A3A:(m.isEnabled()?0xFF152235:0xFF111827));
            if(m.isEnabled()) ctx.fill(x,y,x+3,y+ROW_H,0xFF00BFFF);
            ctx.drawTextWithShadow(client.textRenderer,Text.of(m.name),x+8,y+6,m.isEnabled()?0xFF00BFFF:(sel?0xFFCCDDEE:0xFF8899AA));
            y+=ROW_H+2;
        }
    }
    private void renderSettings(DrawContext ctx,int mx,int my){
        int x=PADDING+SIDEBAR_W+MODULE_W+8,y=24;
        ctx.fill(x,y-2,x+SETTING_W,y+selectedModule.getSettings().size()*(ROW_H+2)+10,0xFF0D1520);
        ctx.drawTextWithShadow(client.textRenderer,Text.of("§f"+selectedModule.name),x+6,y,0xFFFFFF);
        y+=ROW_H;
        for(Setting<?> s:selectedModule.getSettings()){
            if(s instanceof BooleanSetting bs) renderToggle(ctx,x,y,bs,mx,my);
            else if(s instanceof NumberSetting ns) renderSlider(ctx,x,y,ns,mx,my);
            else if(s instanceof ModeSetting ms) renderMode(ctx,x,y,ms,mx,my);
            y+=ROW_H+2;
        }
    }
    private void renderToggle(DrawContext ctx,int x,int y,BooleanSetting s,int mx,int my){
        ctx.fill(x,y,x+SETTING_W,y+ROW_H,0xFF141E2B);
        ctx.drawTextWithShadow(client.textRenderer,Text.of(s.name),x+6,y+6,0xFFCCCCCC);
        boolean on=s.getValue(); int knobX=on?x+SETTING_W-20:x+SETTING_W-34;
        ctx.fill(x+SETTING_W-36,y+6,x+SETTING_W-4,y+14,on?0xFF00BFFF:0xFF334455);
        ctx.fill(knobX,y+4,knobX+14,y+16,0xFFFFFFFF);
    }
    private void renderSlider(DrawContext ctx,int x,int y,NumberSetting s,int mx,int my){
        ctx.fill(x,y,x+SETTING_W,y+ROW_H,0xFF141E2B);
        ctx.drawTextWithShadow(client.textRenderer,Text.of(s.name+": §f"+String.format("%.2f",s.getValue())),x+6,y+6,0xFFCCCCCC);
        int tx=x+6,ty=y+ROW_H-5,tw=SETTING_W-12;
        ctx.fill(tx,ty,tx+tw,ty+3,0xFF223344);
        float pct=(float)((s.getValue()-s.min)/(s.max-s.min));
        ctx.fill(tx,ty,tx+(int)(tw*pct),ty+3,0xFF00BFFF);
        int kx=tx+(int)(tw*pct)-3; ctx.fill(kx,ty-2,kx+6,ty+5,0xFFFFFFFF);
    }
    private void renderMode(DrawContext ctx,int x,int y,ModeSetting s,int mx,int my){
        ctx.fill(x,y,x+SETTING_W,y+ROW_H,0xFF141E2B);
        ctx.drawTextWithShadow(client.textRenderer,Text.of(s.name+": §b"+s.getValue()),x+6,y+6,0xFFCCCCCC);
        ctx.drawTextWithShadow(client.textRenderer,Text.of("§7▶"),x+SETTING_W-14,y+6,0xFF556677);
    }
    @Override public boolean mouseClicked(double mx,double my,int button){
        int sx=PADDING,sy=24;
        for(Category cat:Category.values()){
            if(mx>=sx&&mx<=sx+SIDEBAR_W&&my>=sy&&my<=sy+ROW_H){selectedCategory=cat;selectedModule=null;return true;}
            sy+=ROW_H+2;
        }
        int lx=PADDING+SIDEBAR_W+4,ly=24;
        for(Module m:AxiomClient.MODULE_MANAGER.getModules().stream().filter(mod->mod.category==selectedCategory).collect(Collectors.toList())){
            if(mx>=lx&&mx<=lx+MODULE_W&&my>=ly&&my<=ly+ROW_H){if(button==0)selectedModule=m;if(button==1)m.toggle();return true;}
            ly+=ROW_H+2;
        }
        if(selectedModule!=null){
            int settX=PADDING+SIDEBAR_W+MODULE_W+8,settY=24+ROW_H;
            for(Setting<?> s:selectedModule.getSettings()){
                if(my>=settY&&my<=settY+ROW_H){
                    if(s instanceof BooleanSetting bs&&mx>=settX+SETTING_W-36) bs.toggle();
                    else if(s instanceof ModeSetting ms&&button==0) ms.cycle();
                    else if(s instanceof NumberSetting ns){dragging=ns;dragStartX=mx;dragStartVal=ns.getValue();}
                    return true;
                }
                settY+=ROW_H+2;
            }
        }
        return super.mouseClicked(mx,my,button);
    }
    @Override public boolean mouseDragged(double mx,double my,int button,double dx,double dy){
        if(dragging instanceof NumberSetting ns){ns.setValue(dragStartVal+(mx-dragStartX)*(ns.max-ns.min)/(SETTING_W-12));return true;}
        return super.mouseDragged(mx,my,button,dx,dy);
    }
    @Override public boolean mouseReleased(double mx,double my,int button){dragging=null;return super.mouseReleased(mx,my,button);}
    @Override public boolean shouldPause(){return false;}
}
