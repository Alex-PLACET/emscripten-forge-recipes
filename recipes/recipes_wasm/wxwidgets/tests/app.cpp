#include "wx/wx.h"

static void OnPaint(wxPaintEvent& event)
{
    wxPaintDC dc((wxWindow*)event.GetEventObject());
    dc.SetBackground(*wxRED_BRUSH);
    dc.Clear();
    dc.SetBrush(*wxWHITE_BRUSH);
    dc.DrawRectangle(40, 40, 120, 60);
    printf("TEST_PAINT_OK\n"); fflush(stdout);
}

static void OnClick(wxCommandEvent&)
{
    printf("TEST_CLICK_OK\n"); fflush(stdout);
}

class TestApp : public wxApp {
public:
    bool OnInit() wxOVERRIDE {
        wxFrame* frame = new wxFrame(NULL, wxID_ANY, "wxWidgets wasm test");
        wxPanel* panel = new wxPanel(frame);
        wxButton* button = new wxButton(panel, wxID_ANY, "Click me", wxPoint(20, 20));
        button->Bind(wxEVT_BUTTON, OnClick);
        panel->Bind(wxEVT_PAINT, OnPaint);
        frame->CreateStatusBar();
        frame->Show(true);
        return true;
    }
};
wxIMPLEMENT_APP(TestApp);
