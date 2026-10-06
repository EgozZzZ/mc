package dev.axiom.module.modules.visual;
import dev.axiom.event.Subscribe;
import dev.axiom.event.events.EventRender3D;
import dev.axiom.module.Category;
import dev.axiom.module.Module;
import dev.axiom.setting.*;
import net.minecraft.client.network.AbstractClientPlayerEntity;
import net.minecraft.client.render.*;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.math.Vec3d;
import org.joml.Matrix4f;
import org.joml.Quaternionf;
import java.awt.Color;
public class Cosmetics extends Module {
    public final BooleanSetting chinaHat       = register(new BooleanSetting("China Hat",       true));
    public final ModeSetting    hatStyle        = register(new ModeSetting("Hat Style","Bamboo","Bamboo","Oni","Straw","Pointy"));
    public final NumberSetting  hatSize         = register(new NumberSetting("Hat Size",   1.0,0.5,2.0));
    public final BooleanSetting hatRibbon       = register(new BooleanSetting("Hat Ribbon",     true));
    public final NumberSetting  ribbonHue       = register(new NumberSetting("Ribbon Hue", 180,0,360));
    public final BooleanSetting wings           = register(new BooleanSetting("Wings",          false));
    public final ModeSetting    wingStyle       = register(new ModeSetting("Wing Style","Feather","Feather","Demon","Butterfly","Crystal"));
    public final BooleanSetting wingFlap        = register(new BooleanSetting("Wing Flap",       true));
    public final NumberSetting  wingSpan        = register(new NumberSetting("Wing Span",  1.4,0.5,3.0));
    public final NumberSetting  wingFlapSpeed   = register(new NumberSetting("Flap Speed", 1.2,0.1,5.0));
    public final BooleanSetting wingGlow        = register(new BooleanSetting("Wing Glow",       true));
    public final BooleanSetting cape            = register(new BooleanSetting("Cape",           false));
    public final ModeSetting    capeStyle       = register(new ModeSetting("Cape Style","Gradient","Gradient","Solid","Animated","Pride"));
    public final NumberSetting  capeLength      = register(new NumberSetting("Cape Length",1.0,0.3,2.0));
    public final BooleanSetting trail           = register(new BooleanSetting("Trail",          false));
    public final ModeSetting    trailStyle      = register(new ModeSetting("Trail Style","Sparkle","Sparkle","Hearts","Stars","Flame","Rainbow"));
    public final NumberSetting  trailDensity    = register(new NumberSetting("Trail Density",2.0,0.5,5.0));
    public final ModeSetting    colorTheme      = register(new ModeSetting("Color Theme","Cyan","Cyan","Red","Purple","Gold","Rainbow","Custom"));
    public final NumberSetting  customHue       = register(new NumberSetting("Custom Hue",200,0,360));
    public final NumberSetting  colorSaturation = register(new NumberSetting("Saturation",0.8,0.0,1.0));
    public final NumberSetting  colorBrightness = register(new NumberSetting("Brightness",1.0,0.0,1.0));
    public final NumberSetting  glowAlpha       = register(new NumberSetting("Glow Alpha",0.35,0.0,1.0));
    public final BooleanSetting aspectOverride  = register(new BooleanSetting("Aspect Override", false));
    public final ModeSetting    aspectPreset    = register(new ModeSetting("Aspect Preset","16:9","16:9","4:3","21:9","1:1","Custom"));
    public final NumberSetting  aspectCustomW   = register(new NumberSetting("Custom W",16,1,32));
    public final NumberSetting  aspectCustomH   = register(new NumberSetting("Custom H",9,1,32));
    private float flapTimer = 0f;
    public Cosmetics() { super("Cosmetics","China hat, wings, cape, trails, color themes, aspect ratio",Category.VISUAL,-1); }
    @Subscribe public void onRender3D(EventRender3D event) {
        if (mc.world==null||mc.player==null) return;
        flapTimer += wingFlapSpeed.getValue().floatValue()*0.05f;
        Vec3d cam = mc.gameRenderer.getCamera().getPos();
        for (var entity:mc.world.getEntities()) {
            if (!(entity instanceof AbstractClientPlayerEntity player)) continue;
            MatrixStack mat=event.matrices; mat.push();
            mat.translate(player.getX()-cam.x, player.getY()-cam.y, player.getZ()-cam.z);
            mat.multiply(new Quaternionf().rotationY((float)Math.toRadians(-player.getYaw()+180f)));
            if (chinaHat.getValue()) renderHat(mat,player);
            if (wings.getValue())    renderWings(mat,player);
            if (cape.getValue())     renderCape(mat,player);
            if (trail.getValue())    renderTrail(mat,player,cam);
            mat.pop();
        }
    }
    private void renderHat(MatrixStack mat, AbstractClientPlayerEntity player) {
        mat.push(); mat.translate(0,1.85,0);
        float scale=hatSize.getValue().floatValue(); mat.scale(scale,scale,scale);
        int primary=getThemeColor(0), accent=getRibbonColor();
        switch(hatStyle.getValue()) {
            case "Bamboo"  -> renderBambooHat(mat,primary,accent);
            case "Oni"     -> renderOniHat(mat,primary,accent);
            case "Straw"   -> renderStrawHat(mat,primary,accent);
            case "Pointy"  -> renderPointyHat(mat,primary,accent);
        }
        mat.pop();
    }
    private void renderBambooHat(MatrixStack mat,int primary,int accent){
        drawDisc(mat,0,0,0,0.55f,8,primary,glowAlpha.getValue().floatValue());
        drawDisc(mat,0,0.02f,0,0.5f,8,primary,0.9f);
        drawCone(mat,0,0,0,0.25f,0.4f,10,primary);
        if(hatRibbon.getValue()) drawRing(mat,0,0.05f,0,0.26f,0.03f,accent);
    }
    private void renderOniHat(MatrixStack mat,int primary,int accent){
        drawDisc(mat,0,0,0,0.6f,10,primary,0.9f);
        drawCone(mat,0,0,0,0.28f,0.5f,10,primary);
        drawCone(mat,-0.15f,0.35f,0f,0.04f,0.15f,6,accent);
        drawCone(mat,0.15f,0.35f,0f,0.04f,0.15f,6,accent);
        if(hatRibbon.getValue()) drawRing(mat,0,0.06f,0,0.29f,0.025f,accent);
    }
    private void renderStrawHat(MatrixStack mat,int primary,int accent){
        drawDisc(mat,0,0,0,0.7f,12,primary,0.85f);
        drawHemisphere(mat,0,0,0,0.22f,8,primary);
        if(hatRibbon.getValue()) drawRing(mat,0,0.03f,0,0.23f,0.04f,accent);
    }
    private void renderPointyHat(MatrixStack mat,int primary,int accent){
        drawDisc(mat,0,0,0,0.4f,8,primary,0.9f);
        drawCone(mat,0,0,0,0.18f,0.75f,8,primary);
        if(hatRibbon.getValue()) drawRing(mat,0,0.04f,0,0.19f,0.03f,accent);
    }
    private void renderWings(MatrixStack mat,AbstractClientPlayerEntity player){
        mat.push(); mat.translate(0,1.2,0.15);
        float span=wingSpan.getValue().floatValue();
        float flap=wingFlap.getValue()?(float)(Math.sin(flapTimer)*0.35):0f;
        int col=getThemeColor(0); float alpha=wingGlow.getValue()?0.75f:0.95f;
        switch(wingStyle.getValue()){
            case "Feather"   -> renderFeatherWings(mat,span,flap,col,alpha);
            case "Demon"     -> renderDemonWings(mat,span,flap,col,alpha);
            case "Butterfly" -> renderButterflyWings(mat,span,flap,col,alpha);
            case "Crystal"   -> renderCrystalWings(mat,span,flap,col,alpha);
        }
        mat.pop();
    }
    private void renderFeatherWings(MatrixStack mat,float span,float flap,int col,float alpha){
        for(int side=-1;side<=1;side+=2) for(int layer=0;layer<3;layer++){
            mat.push(); float lo=layer*0.07f;
            mat.translate(side*0.1f,-lo,0);
            mat.multiply(new Quaternionf().rotationZ((float)Math.toRadians(side*(25+layer*18-flap*30))));
            drawWingQuad(mat,side,span*(1f-layer*0.15f),0.55f*(1f-layer*0.1f),col,alpha-layer*0.12f);
            mat.pop();
        }
    }
    private void renderDemonWings(MatrixStack mat,float span,float flap,int col,float alpha){
        for(int side=-1;side<=1;side+=2){
            mat.push();
            mat.multiply(new Quaternionf().rotationZ((float)Math.toRadians(side*(40-flap*35))));
            drawDemonMembrane(mat,side,span,col,alpha); mat.pop();
        }
    }
    private void renderButterflyWings(MatrixStack mat,float span,float flap,int col,float alpha){
        for(int side=-1;side<=1;side+=2){
            mat.push(); mat.multiply(new Quaternionf().rotationZ((float)Math.toRadians(side*(15-flap*20))));
            drawWingQuad(mat,side,span*0.9f,0.65f,col,alpha); mat.pop();
            mat.push(); mat.translate(side*0.05f,-0.3f,0);
            mat.multiply(new Quaternionf().rotationZ((float)Math.toRadians(side*(35+flap*15))));
            drawWingQuad(mat,side,span*0.55f,0.35f,getThemeColor(1),alpha*0.85f); mat.pop();
        }
    }
    private void renderCrystalWings(MatrixStack mat,float span,float flap,int col,float alpha){
        for(int side=-1;side<=1;side+=2) for(int shard=0;shard<4;shard++){
            mat.push();
            mat.multiply(new Quaternionf().rotationZ((float)Math.toRadians(side*(20+shard*22-flap*25))));
            float hue=(getBaseHue()+shard*15f)%360f;
            int sc=Color.HSBtoRGB(hue/360f,colorSaturation.getValue().floatValue(),colorBrightness.getValue().floatValue());
            drawCrystalShard(mat,side,span*(0.18f-shard*0.02f),0.65f-shard*0.1f,sc,alpha); mat.pop();
        }
    }
    private void renderCape(MatrixStack mat,AbstractClientPlayerEntity player){
        mat.push(); mat.translate(0,1.55,0.15);
        float len=capeLength.getValue().floatValue(); long t=System.currentTimeMillis();
        switch(capeStyle.getValue()){
            case "Gradient" -> drawCapeGradient(mat,0.5f,len,getThemeColor(0),getThemeColor(1),0.85f);
            case "Solid"    -> drawCapeGradient(mat,0.5f,len,getThemeColor(0),getThemeColor(0),0.85f);
            case "Animated" -> { float hue=((t/2000f)%1f); int c=Color.HSBtoRGB(hue,colorSaturation.getValue().floatValue(),colorBrightness.getValue().floatValue()); drawCapeGradient(mat,0.5f,len,c,c,0.8f); }
            case "Pride"    -> drawPrideCape(mat,0.5f,len);
        }
        mat.pop();
    }
    private void renderTrail(MatrixStack mat,AbstractClientPlayerEntity player,Vec3d cam){
        int count=(int)(trailDensity.getValue()*4); long t=System.currentTimeMillis();
        for(int i=0;i<count;i++){
            mat.push();
            mat.translate((float)(Math.sin(t*0.004+i)*0.08),i*0.12f*0.3f,-i*0.12f);
            drawSprite(mat,0.06f*(1f-(float)i/count),getTrailColor(i,t),0.7f*(1f-(float)i/count));
            mat.pop();
        }
    }
    public float getAspectOverride(){
        if(!aspectOverride.getValue()) return -1f;
        return switch(aspectPreset.getValue()){
            case "16:9"->16f/9f; case "4:3"->4f/3f; case "21:9"->21f/9f; case "1:1"->1f;
            case "Custom"->aspectCustomW.getValue().floatValue()/aspectCustomH.getValue().floatValue();
            default->-1f;
        };
    }
    public int getThemeColor(int variant){
        float hue=getBaseHue();
        if(colorTheme.getValue().equals("Rainbow")) hue=((System.currentTimeMillis()*0.0003f)+variant*0.15f)%1f*360f;
        hue=(hue+variant*25f)%360f;
        return Color.HSBtoRGB(hue/360f,colorSaturation.getValue().floatValue(),colorBrightness.getValue().floatValue());
    }
    private float getBaseHue(){
        return switch(colorTheme.getValue()){ case "Cyan"->180f; case "Red"->0f; case "Purple"->280f; case "Gold"->45f; case "Custom"->customHue.getValue().floatValue(); default->180f; };
    }
    private int getRibbonColor(){ return Color.HSBtoRGB(ribbonHue.getValue().floatValue()/360f,0.85f,1f); }
    private int getTrailColor(int index,long t){
        return switch(trailStyle.getValue()){
            case "Rainbow"->Color.HSBtoRGB(((t*0.0005f+index*0.08f)%1f),0.9f,1f);
            case "Flame"->Color.HSBtoRGB(0.05f-index*0.005f,0.9f,1f-index*0.04f);
            default->getThemeColor(index%2);
        };
    }
    private void drawDisc(MatrixStack mat,float x,float y,float z,float radius,int segments,int color,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLE_FAN,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,x,y,z).color(r,g,b,alpha);
        for(int i=0;i<=segments;i++){double a=2*Math.PI*i/segments; buf.vertex(m,x+(float)(Math.cos(a)*radius),y,z+(float)(Math.sin(a)*radius)).color(r,g,b,alpha);}
        tess.draw();
    }
    private void drawCone(MatrixStack mat,float x,float y,float z,float baseR,float height,int segments,int color){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLE_FAN,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,x,y+height,z).color(r,g,b,1f);
        for(int i=0;i<=segments;i++){double a=2*Math.PI*i/segments; buf.vertex(m,x+(float)(Math.cos(a)*baseR),y,z+(float)(Math.sin(a)*baseR)).color(r,g,b,0.9f);}
        tess.draw();
    }
    private void drawHemisphere(MatrixStack mat,float x,float y,float z,float radius,int rings,int color){
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        Tessellator tess=Tessellator.getInstance();
        for(int ring=0;ring<rings;ring++){
            float lat0=(float)(Math.PI/2*ring/rings),lat1=(float)(Math.PI/2*(ring+1)/rings);
            BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLE_STRIP,VertexFormats.POSITION_COLOR);
            for(int seg=0;seg<=10;seg++){double lon=2*Math.PI*seg/10;
                buf.vertex(m,x+(float)(Math.cos(lat0)*Math.cos(lon)*radius),y+(float)(Math.sin(lat0)*radius),z+(float)(Math.cos(lat0)*Math.sin(lon)*radius)).color(r,g,b,0.9f);
                buf.vertex(m,x+(float)(Math.cos(lat1)*Math.cos(lon)*radius),y+(float)(Math.sin(lat1)*radius),z+(float)(Math.cos(lat1)*Math.sin(lon)*radius)).color(r,g,b,0.9f);}
            tess.draw();
        }
    }
    private void drawRing(MatrixStack mat,float x,float y,float z,float radius,float thickness,int color){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLE_STRIP,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        for(int i=0;i<=16;i++){double a=2*Math.PI*i/16; float cx=x+(float)(Math.cos(a)*radius),cz=z+(float)(Math.sin(a)*radius);
            buf.vertex(m,cx,y,cz).color(r,g,b,1f); buf.vertex(m,cx,y+thickness,cz).color(r,g,b,0.6f);}
        tess.draw();
    }
    private void drawWingQuad(MatrixStack mat,int side,float w,float h,int color,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.QUADS,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,0,0,0).color(r,g,b,alpha); buf.vertex(m,side*w,0,0).color(r,g,b,alpha*0.4f);
        buf.vertex(m,side*w,h,0).color(r,g,b,alpha*0.3f); buf.vertex(m,0,h,0).color(r,g,b,alpha);
        tess.draw();
    }
    private void drawDemonMembrane(MatrixStack mat,int side,float span,int color,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLE_FAN,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,0,0,0).color(r,g,b,alpha);
        buf.vertex(m,side*span,0.5f,0).color(r,g,b,alpha*0.5f);
        float[]xs={0.8f,0.65f,0.9f,0.5f},ys={0.1f,0.0f,-0.15f,-0.3f};
        for(int i=0;i<xs.length;i++) buf.vertex(m,side*span*xs[i],ys[i],0).color(r,g,b,alpha*0.6f);
        buf.vertex(m,0,-0.3f,0).color(r,g,b,alpha);
        tess.draw();
    }
    private void drawCrystalShard(MatrixStack mat,int side,float w,float h,int color,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.TRIANGLES,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,0,0,0).color(r,g,b,alpha); buf.vertex(m,side*w,h*0.3f,0).color(r,g,b,alpha*0.5f); buf.vertex(m,side*w*0.6f,h,0).color(r,g,b,alpha*0.3f);
        tess.draw();
    }
    private void drawCapeGradient(MatrixStack mat,float w,float len,int topColor,int botColor,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.QUADS,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float tr=((topColor>>16)&0xFF)/255f,tg=((topColor>>8)&0xFF)/255f,tb=(topColor&0xFF)/255f;
        float br=((botColor>>16)&0xFF)/255f,bg=((botColor>>8)&0xFF)/255f,bb=(botColor&0xFF)/255f;
        buf.vertex(m,-w,0,0.02f).color(tr,tg,tb,alpha); buf.vertex(m,w,0,0.02f).color(tr,tg,tb,alpha);
        buf.vertex(m,w,-len,0.02f).color(br,bg,bb,alpha*0.3f); buf.vertex(m,-w,-len,0.02f).color(br,bg,bb,alpha*0.3f);
        tess.draw();
    }
    private void drawPrideCape(MatrixStack mat,float w,float len){
        int[]stripes={0xE40303,0xFF8C00,0xFFED00,0x008026,0x004DFF,0x750787};
        float stripeH=len/stripes.length;
        Tessellator tess=Tessellator.getInstance();
        for(int i=0;i<stripes.length;i++){
            BufferBuilder buf=tess.begin(VertexFormat.DrawMode.QUADS,VertexFormats.POSITION_COLOR);
            Matrix4f m=mat.peek().getPositionMatrix();
            float y0=-i*stripeH,y1=-(i+1)*stripeH;
            float r=((stripes[i]>>16)&0xFF)/255f,g=((stripes[i]>>8)&0xFF)/255f,b=(stripes[i]&0xFF)/255f;
            buf.vertex(m,-w,y0,0.02f).color(r,g,b,0.9f); buf.vertex(m,w,y0,0.02f).color(r,g,b,0.9f);
            buf.vertex(m,w,y1,0.02f).color(r,g,b,0.9f);  buf.vertex(m,-w,y1,0.02f).color(r,g,b,0.9f);
            tess.draw();
        }
    }
    private void drawSprite(MatrixStack mat,float size,int color,float alpha){
        Tessellator tess=Tessellator.getInstance();
        BufferBuilder buf=tess.begin(VertexFormat.DrawMode.QUADS,VertexFormats.POSITION_COLOR);
        Matrix4f m=mat.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f,g=((color>>8)&0xFF)/255f,b=(color&0xFF)/255f;
        buf.vertex(m,-size,-size,0).color(r,g,b,alpha); buf.vertex(m,size,-size,0).color(r,g,b,alpha);
        buf.vertex(m,size,size,0).color(r,g,b,alpha);   buf.vertex(m,-size,size,0).color(r,g,b,alpha);
        tess.draw();
    }
}
