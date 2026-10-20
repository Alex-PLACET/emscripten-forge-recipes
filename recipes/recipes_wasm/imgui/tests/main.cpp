#include "imgui.h"
#include "imgui_impl_null.h"

#include <cstdio>

int main()
{
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();

    ImGuiIO& io = ImGui::GetIO();
    ImGui::StyleColorsDark();

    if (!ImGui_ImplNull_Init())
    {
        std::fprintf(stderr, "failed to initialize null backend\n");
        return 1;
    }

    bool saw_draw_data = false;
    for (int frame = 0; frame < 5; ++frame)
    {
        ImGui_ImplNull_NewFrame();
        ImGui::NewFrame();

        ImGui::Begin("imgui wasm test");
        ImGui::Text("Hello from WebAssembly, frame %d", frame);
        ImGui::End();

        ImGui::Render();

        ImDrawData* draw_data = ImGui::GetDrawData();
        if (draw_data == nullptr)
        {
            std::fprintf(stderr, "no draw data on frame %d\n", frame);
            return 2;
        }

        // The first frame is empty while the font atlas is being built.
        if (draw_data->CmdLists.Size > 0)
            saw_draw_data = true;
    }

    if (!saw_draw_data)
    {
        std::fprintf(stderr, "no draw lists were produced\n");
        return 3;
    }

    ImGui_ImplNull_Shutdown();
    ImGui::DestroyContext();

    std::printf("imgui test passed (%.1f FPS)\n", io.Framerate);
    return 0;
}
