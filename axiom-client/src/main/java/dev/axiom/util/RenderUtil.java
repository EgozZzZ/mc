package dev.axiom.util;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.render.*;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.entity.LivingEntity;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Vec3d;
import org.joml.Matrix4f;
public class RenderUtil {
    private static final MinecraftClient mc = MinecraftClient.getInstance();
    public static void drawBox(MatrixStack matrices, Box box, int fillColor, int outlineColor) {
        Vec3d cam = mc.gameRenderer.getCamera().getPos();
        matrices.push();
        matrices.translate(-cam.x, -cam.y, -cam.z);
        Tessellator tess = Tessellator.getInstance();
        BufferBuilder buf = tess.begin(VertexFormat.DrawMode.QUADS, VertexFormats.POSITION_COLOR);
        Matrix4f mat = matrices.peek().getPositionMatrix();
        float r=((fillColor>>16)&0xFF)/255f, g=((fillColor>>8)&0xFF)/255f, b=(fillColor&0xFF)/255f, a=((fillColor>>24)&0xFF)/255f;
        addBox(buf, mat, box, r, g, b, a);
        tess.draw();
        matrices.pop();
    }
    private static void addBox(BufferBuilder buf, Matrix4f mat, Box b, float r, float g, float bl, float a) {
        float x0=(float)b.minX,x1=(float)b.maxX,y0=(float)b.minY,y1=(float)b.maxY,z0=(float)b.minZ,z1=(float)b.maxZ;
        buf.vertex(mat,x0,y0,z0).color(r,g,bl,a); buf.vertex(mat,x1,y0,z0).color(r,g,bl,a);
        buf.vertex(mat,x1,y0,z1).color(r,g,bl,a); buf.vertex(mat,x0,y0,z1).color(r,g,bl,a);
        buf.vertex(mat,x0,y1,z0).color(r,g,bl,a); buf.vertex(mat,x1,y1,z0).color(r,g,bl,a);
        buf.vertex(mat,x1,y1,z1).color(r,g,bl,a); buf.vertex(mat,x0,y1,z1).color(r,g,bl,a);
    }
    public static void drawTracer(MatrixStack matrices, Vec3d target, int color) {
        if (mc.player == null) return;
        Vec3d cam = mc.gameRenderer.getCamera().getPos();
        Vec3d screen = mc.player.getEyePos();
        matrices.push();
        matrices.translate(-cam.x, -cam.y, -cam.z);
        Tessellator tess = Tessellator.getInstance();
        BufferBuilder buf = tess.begin(VertexFormat.DrawMode.DEBUG_LINES, VertexFormats.POSITION_COLOR);
        Matrix4f mat = matrices.peek().getPositionMatrix();
        float r=((color>>16)&0xFF)/255f, g=((color>>8)&0xFF)/255f, bl=(color&0xFF)/255f;
        buf.vertex(mat,(float)screen.x,(float)screen.y,(float)screen.z).color(r,g,bl,1f);
        buf.vertex(mat,(float)target.x,(float)target.y,(float)target.z).color(r,g,bl,1f);
        tess.draw();
        matrices.pop();
    }
    public static void drawHealthBar(MatrixStack matrices, LivingEntity entity) {}
}
