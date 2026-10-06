package dev.axiom.event;
import java.lang.reflect.Method;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
public class EventBus {
    private final Map<Class<?>, List<ListenerMethod>> listeners = new ConcurrentHashMap<>();
    public void subscribe(Object object) {
        for (Method method : object.getClass().getDeclaredMethods()) {
            if (method.isAnnotationPresent(Subscribe.class) && method.getParameterCount() == 1) {
                Class<?> eventType = method.getParameterTypes()[0];
                listeners.computeIfAbsent(eventType, k -> new ArrayList<>())
                         .add(new ListenerMethod(object, method));
            }
        }
    }
    public void unsubscribe(Object object) {
        listeners.values().forEach(list -> list.removeIf(lm -> lm.instance == object));
    }
    public void post(Object event) {
        List<ListenerMethod> list = listeners.get(event.getClass());
        if (list == null) return;
        for (ListenerMethod lm : list) {
            try { lm.method.invoke(lm.instance, event); }
            catch (Exception e) { dev.axiom.AxiomClient.LOGGER.error("EventBus error", e); }
        }
    }
    private record ListenerMethod(Object instance, Method method) {}
}
