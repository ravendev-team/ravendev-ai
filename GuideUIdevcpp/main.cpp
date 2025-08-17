#define UNICODE
#define _UNICODE
#include <windows.h>
#include <vector>
#include <string>
#include <memory>
#include <algorithm>
#include <cmath>
#include <gdiplus.h>

// 라이브러리 링크 (Dev-C++용)
#pragma comment(lib, "gdiplus")
#pragma comment(lib, "gdi32")
#pragma comment(lib, "user32")
#pragma comment(lib, "kernel32")
#pragma comment(lib, "ole32")
#pragma comment(lib, "uuid")


using namespace std;
using namespace Gdiplus;

// 전방 선언
class Node;
class NodePort;
class Connection;
class NodeCanvas;

// 열거형 정의
enum class NodeType {
    Original,
    Step01,
    Step02,
    Step03,
    Step04,
    Step05
};

enum class PortType {
    Input,
    Output
};

// NodePort 클래스
class NodePort {
public:
    string name;
    PortType type;
    Node* parentNode;
    RECT bounds;
    
    NodePort(const string& n, PortType t, Node* parent) 
        : name(n), type(t), parentNode(parent) {
        bounds = {0, 0, 0, 0};
    }
};

// Node 클래스
class Node {
public:
    string title;
    POINT position;
    NodeType type;
    vector<std::unique_ptr<NodePort>> inputPorts;
    vector<std::unique_ptr<NodePort>> outputPorts;
    vector<string> inputImageNames;
    vector<string> outputImageNames;
    vector<std::shared_ptr<Image>> inputImages;  // 실제 이미지 객체들
    vector<std::shared_ptr<Image>> outputImages; // 실제 이미지 객체들
    
    Node(const string& t, POINT pos, NodeType nt) 
        : title(t), position(pos), type(nt) {}
    
    void AddInputPort(const string& name) {
        inputPorts.push_back(std::make_unique<NodePort>(name, PortType::Input, this));
    }
    
    void AddOutputPort(const string& name) {
        outputPorts.push_back(std::make_unique<NodePort>(name, PortType::Output, this));
    }
    
    // 파일 확장자 확인 함수
    bool IsGifFile(const string& filename) {
        if (filename.length() < 4) return false;
        string extension = filename.substr(filename.length() - 4);
        transform(extension.begin(), extension.end(), extension.begin(), ::tolower);
        return extension == ".gif";
    }
    
    void LoadImages(const vector<string>& filenames) {
        outputImageNames.clear();
        outputImages.clear();
        
        for (const auto& filename : filenames) {
            outputImageNames.push_back(filename);
            
            // GIF 파일인지 확인
            if (IsGifFile(filename)) {
                // GIF 파일의 경우 nullptr을 추가하고 계속 진행
                outputImages.push_back(nullptr);
                continue;
            }
            
            // 실제 이미지 로드
            wstring wFilename(filename.begin(), filename.end());
            auto image = std::make_shared<Image>(wFilename.c_str());
            
            if (image->GetLastStatus() == Ok) {
                outputImages.push_back(image);
            } else {
                // 이미지 로드 실패 시 nullptr 추가
                outputImages.push_back(nullptr);
            }
        }
    }
    
    void SetInputImages(const vector<string>& imageNames) {
        inputImageNames.clear();
        inputImages.clear();
        
        for (const auto& name : imageNames) {
            inputImageNames.push_back(name);
            
            // GIF 파일인지 확인
            if (IsGifFile(name)) {
                // GIF 파일의 경우 nullptr을 추가하고 계속 진행
                inputImages.push_back(nullptr);
                continue;
            }
            
            // 실제 이미지 로드
            wstring wFilename(name.begin(), name.end());
            auto image = std::make_shared<Image>(wFilename.c_str());
            
            if (image->GetLastStatus() == Ok) {
                inputImages.push_back(image);
            } else {
                inputImages.push_back(nullptr);
            }
        }
    }
    
    void SetInputImagesFromNode(Node* sourceNode) {
        inputImageNames = sourceNode->outputImageNames;
        inputImages = sourceNode->outputImages;
    }
    
    int GetWidth() const {
        int maxImages = max(inputImageNames.size(), outputImageNames.size());
        int imagesPerRow = min(4, maxImages);
        return max(250, 20 + imagesPerRow * 70);
    }
    
    int GetHeight() const {
        int inputRows = inputImageNames.empty() ? 0 : (inputImageNames.size() - 1) / 4 + 1;
        int outputRows = outputImageNames.empty() ? 0 : (outputImageNames.size() - 1) / 4 + 1;
        
        int baseHeight = 80;
        int imageHeight = (inputRows + outputRows) * 80;
        
        if (inputRows > 0) imageHeight += 30;
        if (outputRows > 0) imageHeight += 30;
        
        return max(baseHeight, baseHeight + imageHeight);
    }
    
    COLORREF GetNodeColor() const {
        switch (type) {
            case NodeType::Original: return RGB(70, 130, 180);
            case NodeType::Step01: return RGB(220, 20, 60);
            case NodeType::Step02: return RGB(255, 140, 0);
            case NodeType::Step03: return RGB(50, 205, 50);
            case NodeType::Step04: return RGB(138, 43, 226);
            case NodeType::Step05: return RGB(255, 20, 147);
            default: return RGB(70, 70, 74);
        }
    }
};

// Connection 클래스
class Connection {
public:
    NodePort* outputPort;
    NodePort* inputPort;
    
    Connection(NodePort* out, NodePort* in) 
        : outputPort(out), inputPort(in) {}
};


// 간단한 상태바 클래스
class SimpleStatusBar {
private:
    HWND parentHwnd;
    wstring message;  // string을 wstring으로 변경
    int height;
    
public:
    SimpleStatusBar(HWND parent) : parentHwnd(parent), height(25) {
        message = L"준비됨 - 노드를 연결하여 이미지 처리 워크플로우를 시작하세요";  // L 접두사 추가
    }
    
    void SetText(const string& text) {
        // string을 wstring으로 변환
        message = wstring(text.begin(), text.end());
        InvalidateRect(parentHwnd, NULL, FALSE);
    }
    
    void SetTextW(const wstring& text) {  // 유니코드 텍스트 설정 메서드 추가
        message = text;
        InvalidateRect(parentHwnd, NULL, FALSE);
    }
    
    void Draw(HDC hdc, const RECT& clientRect) {
        RECT statusRect = {
            clientRect.left,
            clientRect.bottom - height,
            clientRect.right,
            clientRect.bottom
        };
        
        // 배경 그리기
        HBRUSH brush = CreateSolidBrush(RGB(240, 240, 240));
        FillRect(hdc, &statusRect, brush);
        DeleteObject(brush);
        
        // 테두리 그리기
        HPEN pen = CreatePen(PS_SOLID, 1, RGB(160, 160, 160));
        HPEN oldPen = (HPEN)SelectObject(hdc, pen);
        
        MoveToEx(hdc, statusRect.left, statusRect.top, NULL);
        LineTo(hdc, statusRect.right, statusRect.top);
        
        SelectObject(hdc, oldPen);
        DeleteObject(pen);
        
        // 텍스트 그리기 (유니코드 버전 사용)
        SetTextColor(hdc, RGB(0, 0, 0));
        SetBkMode(hdc, TRANSPARENT);
        
        RECT textRect = statusRect;
        textRect.left += 10;
        textRect.right -= 10;
        
        DrawTextW(hdc, message.c_str(), -1, &textRect, 
                 DT_LEFT | DT_VCENTER | DT_SINGLELINE);
    }
    
    int GetHeight() const { return height; }
};

// NodeCanvas 클래스
class NodeCanvas {
private:
    HWND hwnd;
    vector<std::unique_ptr<Node>> nodes;
    vector<std::unique_ptr<Connection>> connections;
    Node* draggedNode = nullptr;
    NodePort* connectionStartPort = nullptr;
    POINT lastMousePos;
    POINT canvasOffset;
    bool isPanning = false;
    float zoomLevel = 1.0f;
    
    // 더블 버퍼링을 위한 변수들
    HDC memDC = nullptr;
    HBITMAP memBitmap = nullptr;
    HBITMAP oldBitmap = nullptr;
    
public:
    NodeCanvas(HWND h) : hwnd(h) {
        canvasOffset = {0, 0};
        InitializeNodes();
        SetupDoubleBuffering();
    }
    
    ~NodeCanvas() {
        CleanupDoubleBuffering();
    }
    
    void SetupDoubleBuffering() {
        HDC hdc = GetDC(hwnd);
        memDC = CreateCompatibleDC(hdc);
        
        RECT rect;
        GetClientRect(hwnd, &rect);
        memBitmap = CreateCompatibleBitmap(hdc, rect.right, rect.bottom);
        oldBitmap = (HBITMAP)SelectObject(memDC, memBitmap);
        
        ReleaseDC(hwnd, hdc);
    }
    
    void CleanupDoubleBuffering() {
        if (memDC) {
            SelectObject(memDC, oldBitmap);
            DeleteObject(memBitmap);
            DeleteDC(memDC);
        }
    }
    
    void OnResize() {
        CleanupDoubleBuffering();
        SetupDoubleBuffering();
    }
    
    void InitializeNodes() {
        // 원본 이미지 노드
        auto originalNode = std::make_unique<Node>("원본이미지", POINT{50, 30}, NodeType::Original);
        originalNode->AddOutputPort("Output");
        originalNode->LoadImages({"images/input.png"});
        nodes.push_back(std::move(originalNode));
        
        // Step01 노드
        auto step01Node = std::make_unique<Node>("Step01", POINT{300, 30}, NodeType::Step01);
        step01Node->AddInputPort("Input");
        step01Node->AddOutputPort("Output");
        nodes.push_back(std::move(step01Node));
        
        // Step02 노드
        auto step02Node = std::make_unique<Node>("Step02", POINT{600, 30}, NodeType::Step02);
        step02Node->AddInputPort("Input");
        step02Node->AddOutputPort("Output");
        nodes.push_back(std::move(step02Node));
        
        // Step03 노드
        auto step03Node = std::make_unique<Node>("Step03", POINT{300, 330}, NodeType::Step03);
        step03Node->AddInputPort("Input");
        step03Node->AddOutputPort("Output");
        nodes.push_back(std::move(step03Node));
        
        // Step04 노드
        auto step04Node = std::make_unique<Node>("Step04", POINT{600, 330}, NodeType::Step04);
        step04Node->AddInputPort("Input");
        step04Node->AddOutputPort("Output");
        nodes.push_back(std::move(step04Node));
        
        // Step05 노드
        auto step05Node = std::make_unique<Node>("Step05", POINT{900, 330}, NodeType::Step05);
        step05Node->AddInputPort("Input");
        step05Node->AddOutputPort("Output");
        nodes.push_back(std::move(step05Node));
    }
    
    
void OnPaint(HDC hdc, SimpleStatusBar* statusBar) {
        RECT clientRect;
        GetClientRect(hwnd, &clientRect);
        
        // 상태바 영역 제외
        RECT canvasRect = clientRect;
        if (statusBar) {
            canvasRect.bottom -= statusBar->GetHeight();
        }
        
        // 배경을 어두운 색으로 채우기 (C# 원본과 같은 색상)
        HBRUSH bgBrush = CreateSolidBrush(RGB(45, 45, 48));
        FillRect(memDC, &canvasRect, bgBrush);
        DeleteObject(bgBrush);
        
        // 변환 적용
        SetGraphicsMode(memDC, GM_ADVANCED);
        XFORM xform;
        xform.eM11 = zoomLevel;
        xform.eM12 = 0;
        xform.eM21 = 0;
        xform.eM22 = zoomLevel;
        xform.eDx = (float)canvasOffset.x;
        xform.eDy = (float)canvasOffset.y;
        SetWorldTransform(memDC, &xform);
        
        DrawGrid(memDC, canvasRect);
        DrawConnections(memDC);
        
        if (connectionStartPort != nullptr) {
            DrawTempConnection(memDC);
        }
        
        DrawNodes(memDC);
        
        // 변환 리셋
        ModifyWorldTransform(memDC, NULL, MWT_IDENTITY);
        
        // 메모리 DC에서 실제 DC로 복사
        BitBlt(hdc, 0, 0, clientRect.right, clientRect.bottom, memDC, 0, 0, SRCCOPY);
        
        // 상태바 그리기
        if (statusBar) {
            statusBar->Draw(hdc, clientRect);
        }
    }
    
    void DrawGrid(HDC hdc, const RECT& canvasRect) {
        HPEN gridPen = CreatePen(PS_SOLID, 1, RGB(60, 60, 63));
        HPEN oldPen = (HPEN)SelectObject(hdc, gridPen);
        
        int gridSize = 20;
        int startX = -(canvasOffset.x % gridSize);
        int startY = -(canvasOffset.y % gridSize);
        
        for (int x = startX; x < canvasRect.right / zoomLevel; x += gridSize) {
            MoveToEx(hdc, x, 0, NULL);
            LineTo(hdc, x, (int)(canvasRect.bottom / zoomLevel));
        }
        
        for (int y = startY; y < canvasRect.bottom / zoomLevel; y += gridSize) {
            MoveToEx(hdc, 0, y, NULL);
            LineTo(hdc, (int)(canvasRect.right / zoomLevel), y);
        }
        
        SelectObject(hdc, oldPen);
        DeleteObject(gridPen);
    }
    
    void DrawNodes(HDC hdc) {
        for (const auto& node : nodes) {
            DrawNode(hdc, node.get());
        }
    }
    
    void DrawNode(HDC hdc, Node* node) {
        if (!node) return;
        
        int nodeWidth = node->GetWidth();
        int nodeHeight = node->GetHeight();
        RECT nodeRect = {
            node->position.x, 
            node->position.y, 
            node->position.x + nodeWidth, 
            node->position.y + nodeHeight
        };
        
        // 둥근 사각형으로 노드 그리기 (C# 원본과 유사하게)
        DrawRoundedRectangle(hdc, nodeRect, node->GetNodeColor(), 8);
        
        // 노드 제목 그리기
        DrawNodeTitle(hdc, node, nodeRect);
        
        // 이미지 영역 그리기
        DrawNodeImages(hdc, node, nodeRect);
        
        // 포트 그리기
        DrawNodePorts(hdc, node, nodeRect);
    }
    
    void DrawRoundedRectangle(HDC hdc, const RECT& rect, COLORREF color, int radius) {
        // 노드 배경 그리기 (그라디언트 효과 대신 단색)
        HBRUSH brush = CreateSolidBrush(color);
        HPEN pen = CreatePen(PS_SOLID, 2, RGB(150, 150, 154));
        
        HBRUSH oldBrush = (HBRUSH)SelectObject(hdc, brush);
        HPEN oldPen = (HPEN)SelectObject(hdc, pen);
        
        RoundRect(hdc, rect.left, rect.top, rect.right, rect.bottom, radius, radius);
        
        SelectObject(hdc, oldBrush);
        SelectObject(hdc, oldPen);
        DeleteObject(brush);
        DeleteObject(pen);
    }
    
    void DrawNodeTitle(HDC hdc, Node* node, const RECT& nodeRect) {
        if (!node) return;
        
        SetTextColor(hdc, RGB(255, 255, 255));
        SetBkMode(hdc, TRANSPARENT);
        
        // 폰트 설정
        HFONT font = CreateFont(
            16, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
            DEFAULT_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS,
            CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI"
        );
        HFONT oldFont = (HFONT)SelectObject(hdc, font);
        
        RECT titleRect = {
            nodeRect.left + 10, 
            nodeRect.top + 8, 
            nodeRect.right - 10, 
            nodeRect.top + 35
        };
        
        // string을 wstring으로 변환
        wstring title(node->title.begin(), node->title.end());
        DrawTextW(hdc, title.c_str(), -1, &titleRect, 
                 DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        
        SelectObject(hdc, oldFont);
        DeleteObject(font);
    }
    
    void DrawNodeImages(HDC hdc, Node* node, const RECT& nodeRect) {
        if (!node) return;
        
        // GDI+를 위한 Graphics 객체 생성
        Graphics graphics(hdc);
        graphics.SetInterpolationMode(InterpolationModeHighQualityBicubic);
        
        int imageY = nodeRect.top + 40;
        int imageSize = 60;
        int spacing = 5;
        
        // Input 이미지들 표시
        if (!node->inputImageNames.empty()) {
            // "INPUT" 라벨 그리기
            SetTextColor(hdc, RGB(173, 216, 230)); // LightBlue
            HFONT labelFont = CreateFont(
                12, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                DEFAULT_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS,
                CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI"
            );
            HFONT oldFont = (HFONT)SelectObject(hdc, labelFont);
            
            TextOutW(hdc, nodeRect.left + 10, imageY - 20, L"INPUT", 5);
            
            SelectObject(hdc, oldFont);
            DeleteObject(labelFont);
            
            int inputImagesPerRow = min(4, (int)node->inputImageNames.size());
            int inputRowHeight = imageSize + spacing;
            
            for (size_t i = 0; i < node->inputImageNames.size(); i++) {
                int row = i / inputImagesPerRow;
                int col = i % inputImagesPerRow;
                
                int x = nodeRect.left + 10 + col * (imageSize + spacing);
                int y = imageY + row * inputRowHeight;
                
                // 실제 이미지가 있으면 그리기, 없으면 플레이스홀더
                if (i < node->inputImages.size() && node->inputImages[i]) {
                    // GDI+로 이미지 그리기
                    Rect destRect(x, y, imageSize, imageSize);
                    graphics.DrawImage(node->inputImages[i].get(), destRect);
                } else {
                    // 플레이스홀더 그리기
                    RECT imgRect = {x, y, x + imageSize, y + imageSize};
                    DrawImagePlaceholder(hdc, imgRect, node->inputImageNames[i], RGB(100, 100, 150));
                }
            }
            
            imageY += ((node->inputImageNames.size() - 1) / inputImagesPerRow + 1) * inputRowHeight + 25;
        }
        
        // Output 이미지들 표시
        if (!node->outputImageNames.empty()) {
            // "OUTPUT" 라벨 그리기
            SetTextColor(hdc, RGB(255, 165, 0)); // Orange
            HFONT labelFont = CreateFont(
                12, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                DEFAULT_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS,
                CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI"
            );
            HFONT oldFont = (HFONT)SelectObject(hdc, labelFont);
            
            TextOutW(hdc, nodeRect.left + 10, imageY - 20, L"OUTPUT", 6);
            
            SelectObject(hdc, oldFont);
            DeleteObject(labelFont);
            
            int outputImagesPerRow = min(4, (int)node->outputImageNames.size());
            int outputRowHeight = imageSize + spacing;
            
            for (size_t i = 0; i < node->outputImageNames.size(); i++) {
                int row = i / outputImagesPerRow;
                int col = i % outputImagesPerRow;
                
                int x = nodeRect.left + 10 + col * (imageSize + spacing);
                int y = imageY + row * outputRowHeight;
                
                // 실제 이미지가 있으면 그리기, 없으면 플레이스홀더
                if (i < node->outputImages.size() && node->outputImages[i]) {
                    // GDI+로 이미지 그리기
                    Rect destRect(x, y, imageSize, imageSize);
                    graphics.DrawImage(node->outputImages[i].get(), destRect);
                } else {
                    // 플레이스홀더 그리기
                    RECT imgRect = {x, y, x + imageSize, y + imageSize};
                    DrawImagePlaceholder(hdc, imgRect, node->outputImageNames[i], RGB(150, 100, 100));
                }
            }
        }
    }
    
    void DrawImagePlaceholder(HDC hdc, const RECT& rect, const string& filename, COLORREF bgColor) {
        // 배경 그리기
        HBRUSH brush = CreateSolidBrush(bgColor);
        FillRect(hdc, &rect, brush);
        DeleteObject(brush);
        
        // 테두리 그리기
        HPEN pen = CreatePen(PS_SOLID, 1, RGB(128, 128, 128));
        HPEN oldPen = (HPEN)SelectObject(hdc, pen);
        
        Rectangle(hdc, rect.left, rect.top, rect.right, rect.bottom);
        
        SelectObject(hdc, oldPen);
        DeleteObject(pen);
        
        // 파일명 표시
        SetTextColor(hdc, RGB(255, 255, 255));
        SetBkMode(hdc, TRANSPARENT);
        
        HFONT font = CreateFont(
            8, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
            DEFAULT_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS,
            CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI"
        );
        HFONT oldFont = (HFONT)SelectObject(hdc, font);
        
        // 파일명에서 확장자 제거하고 길이 제한
        string displayName = filename;
        size_t dotPos = displayName.find_last_of('.');
        if (dotPos != string::npos) {
            displayName = displayName.substr(0, dotPos);
        }
        size_t slashPos = displayName.find_last_of('/');
        if (slashPos != string::npos) {
            displayName = displayName.substr(slashPos + 1);
        }
        
        if (displayName.length() > 8) {
            displayName = displayName.substr(0, 8) + "...";
        }
        
        // string을 wstring으로 변환
        wstring wDisplayName(displayName.begin(), displayName.end());
        
        RECT textRect = rect;
        DrawTextW(hdc, wDisplayName.c_str(), -1, &textRect, 
                 DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_WORDBREAK);
        
        SelectObject(hdc, oldFont);
        DeleteObject(font);
    }
	
	
void DrawNodePorts(HDC hdc, Node* node, const RECT& nodeRect) {
        if (!node) return;
        
        int portY = nodeRect.bottom - 30;
        
        // Input 포트들 그리기
        for (const auto& port : node->inputPorts) {
            POINT portPos = {nodeRect.left - 8, portY};
            DrawPort(hdc, port.get(), portPos);
            
            // 포트 라벨 (유니코드 변환)
            SetTextColor(hdc, RGB(211, 211, 211)); // LightGray
            SetBkMode(hdc, TRANSPARENT);
            wstring portName(port->name.begin(), port->name.end());
            TextOutW(hdc, nodeRect.left + 15, portY - 8, portName.c_str(), portName.length());
        }
        
        // Output 포트들 그리기
        for (const auto& port : node->outputPorts) {
            POINT portPos = {nodeRect.right - 8, portY};
            DrawPort(hdc, port.get(), portPos);
            
            // 포트 라벨 (오른쪽 정렬, 유니코드 변환)
            SetTextColor(hdc, RGB(211, 211, 211)); // LightGray
            SetBkMode(hdc, TRANSPARENT);
            
            wstring portName(port->name.begin(), port->name.end());
            SIZE textSize;
            GetTextExtentPoint32W(hdc, portName.c_str(), portName.length(), &textSize);
            TextOutW(hdc, nodeRect.right - textSize.cx - 15, portY - 8, 
                    portName.c_str(), portName.length());
        }
    }
    
    void DrawPort(HDC hdc, NodePort* port, const POINT& position) {
        if (!port) return;
        
        RECT portRect = {
            position.x - 8, 
            position.y - 8, 
            position.x + 8, 
            position.y + 8
        };
        port->bounds = portRect;
        
        COLORREF portColor = (port->type == PortType::Input) ? 
            RGB(173, 216, 230) : RGB(255, 165, 0);
        
        HBRUSH brush = CreateSolidBrush(portColor);
        HPEN pen = CreatePen(PS_SOLID, 2, RGB(255, 255, 255));
        
        HBRUSH oldBrush = (HBRUSH)SelectObject(hdc, brush);
        HPEN oldPen = (HPEN)SelectObject(hdc, pen);
        
        Ellipse(hdc, portRect.left, portRect.top, portRect.right, portRect.bottom);
        
        SelectObject(hdc, oldBrush);
        SelectObject(hdc, oldPen);
        DeleteObject(brush);
        DeleteObject(pen);
    }
    
    void DrawConnections(HDC hdc) {
        for (const auto& connection : connections) {
            DrawConnection(hdc, connection.get());
        }
    }
    
    void DrawConnection(HDC hdc, Connection* connection) {
        if (!connection) return;
        
        POINT startPos = GetPortCenter(connection->outputPort);
        POINT endPos = GetPortCenter(connection->inputPort);
        
        // 베지어 곡선으로 연결선 그리기 (C# 원본과 유사하게)
        DrawBezierConnection(hdc, startPos, endPos, RGB(255, 255, 0), 3);
    }
    
    void DrawTempConnection(HDC hdc) {
        if (!connectionStartPort) return;
        
        POINT startPos = GetPortCenter(connectionStartPort);
        POINT endPos = {
            (int)((lastMousePos.x - canvasOffset.x) / zoomLevel),
            (int)((lastMousePos.y - canvasOffset.y) / zoomLevel)
        };
        
        DrawBezierConnection(hdc, startPos, endPos, RGB(128, 128, 128), 2);
    }
    
    void DrawBezierConnection(HDC hdc, const POINT& start, const POINT& end, COLORREF color, int width) {
        HPEN pen = CreatePen(PS_SOLID, width, color);
        HPEN oldPen = (HPEN)SelectObject(hdc, pen);
        
        // 베지어 곡선을 위한 제어점 계산
        int controlOffset = abs(end.x - start.x) / 2;
        POINT control1 = {start.x + controlOffset, start.y};
        POINT control2 = {end.x - controlOffset, end.y};
        
        // 베지어 곡선을 여러 선분으로 근사
        const int segments = 20;
        POINT prevPoint = start;
        
        for (int i = 1; i <= segments; i++) {
            float t = (float)i / segments;
            POINT currentPoint = CalculateBezierPoint(start, control1, control2, end, t);
            
            MoveToEx(hdc, prevPoint.x, prevPoint.y, NULL);
            LineTo(hdc, currentPoint.x, currentPoint.y);
            
            prevPoint = currentPoint;
        }
        
        SelectObject(hdc, oldPen);
        DeleteObject(pen);
    }
    
    POINT CalculateBezierPoint(const POINT& p0, const POINT& p1, const POINT& p2, const POINT& p3, float t) {
        float u = 1 - t;
        float tt = t * t;
        float uu = u * u;
        float uuu = uu * u;
        float ttt = tt * t;
        
        float x = uuu * p0.x + 3 * uu * t * p1.x + 3 * u * tt * p2.x + ttt * p3.x;
        float y = uuu * p0.y + 3 * uu * t * p1.y + 3 * u * tt * p2.y + ttt * p3.y;
        
        return {(int)x, (int)y};
    }
    
    POINT GetPortCenter(NodePort* port) {
        if (!port) return {0, 0};
        
        return {
            (port->bounds.left + port->bounds.right) / 2,
            (port->bounds.top + port->bounds.bottom) / 2
        };
    }
    
    Node* GetNodeAtPosition(const POINT& position) {
        POINT adjustedPos = {
            (int)((position.x - canvasOffset.x) / zoomLevel),
            (int)((position.y - canvasOffset.y) / zoomLevel)
        };
        
        for (auto it = nodes.rbegin(); it != nodes.rend(); ++it) {
            Node* node = it->get();
            RECT nodeRect = {
                node->position.x, 
                node->position.y,
                node->position.x + node->GetWidth(),
                node->position.y + node->GetHeight()
            };
            
            if (PtInRect(&nodeRect, adjustedPos)) {
                return node;
            }
        }
        return nullptr;
    }
    
    NodePort* GetPortAtPosition(const POINT& position) {
        POINT adjustedPos = {
            (int)((position.x - canvasOffset.x) / zoomLevel),
            (int)((position.y - canvasOffset.y) / zoomLevel)
        };
        
        for (const auto& node : nodes) {
            for (const auto& port : node->inputPorts) {
                if (PtInRect(&port->bounds, adjustedPos)) {
                    return port.get();
                }
            }
            
            for (const auto& port : node->outputPorts) {
                if (PtInRect(&port->bounds, adjustedPos)) {
                    return port.get();
                }
            }
        }
        return nullptr;
    }
    
    void OnMouseDown(int x, int y, UINT flags) {
        lastMousePos = {x, y};
        
        if (flags & MK_MBUTTON) {
            isPanning = true;
            return;
        }
        
        // 우클릭으로 연결 제거
        if (flags & MK_RBUTTON) {
            auto clickedConnection = GetConnectionAtPosition({x, y});
            if (clickedConnection) {
                RemoveConnection(clickedConnection);
                InvalidateRect(hwnd, NULL, FALSE);
                return;
            }
            
            if (connectionStartPort) {
                connectionStartPort = nullptr;
                InvalidateRect(hwnd, NULL, FALSE);
                return;
            }
        }
        
        // 포트 클릭 확인
        NodePort* clickedPort = GetPortAtPosition({x, y});
        if (clickedPort && (flags & MK_LBUTTON)) {
            if (!connectionStartPort) {
                connectionStartPort = clickedPort;
            } else {
                // 연결 생성
                if (CanConnect(connectionStartPort, clickedPort)) {
                    connections.push_back(
                        std::make_unique<Connection>(connectionStartPort, clickedPort));
                    ProcessImageFlow(connectionStartPort, clickedPort);
                }
                connectionStartPort = nullptr;
            }
            InvalidateRect(hwnd, NULL, FALSE);
            return;
        }
        
        // 노드 클릭 확인
        if (flags & MK_LBUTTON) {
            draggedNode = GetNodeAtPosition({x, y});
            if (draggedNode) {
                // 드래그된 노드를 맨 앞으로 이동 (Z-order)
                auto it = std::find_if(nodes.begin(), nodes.end(), 
                    [this](const std::unique_ptr<Node>& node) { return node.get() == draggedNode; });
                if (it != nodes.end()) {
                    auto nodePtr = std::move(*it);
                    nodes.erase(it);
                    nodes.push_back(std::move(nodePtr));
                }
            }
        }
    }
    
    void OnMouseMove(int x, int y, UINT flags) {
        if (isPanning) {
            canvasOffset.x += x - lastMousePos.x;
            canvasOffset.y += y - lastMousePos.y;
            InvalidateRect(hwnd, NULL, FALSE);
        } else if (draggedNode) {
            draggedNode->position.x += (int)((x - lastMousePos.x) / zoomLevel);
            draggedNode->position.y += (int)((y - lastMousePos.y) / zoomLevel);
            InvalidateRect(hwnd, NULL, FALSE);
        } else if (connectionStartPort) {
            InvalidateRect(hwnd, NULL, FALSE);
        }
        
        lastMousePos = {x, y};
    }
    
    void OnMouseUp(int x, int y, UINT flags) {
        draggedNode = nullptr;
        isPanning = false;
    }
    
    void OnMouseWheel(short delta) {
        float oldZoom = zoomLevel;
        zoomLevel += (delta > 0) ? 0.1f : -0.1f;
        zoomLevel = max(0.1f, min(3.0f, zoomLevel));
        
        if (oldZoom != zoomLevel) {
            InvalidateRect(hwnd, NULL, FALSE);
        }
    }
	
Connection* GetConnectionAtPosition(const POINT& position) {
        POINT adjustedPos = {
            (int)((position.x - canvasOffset.x) / zoomLevel),
            (int)((position.y - canvasOffset.y) / zoomLevel)
        };
        
        for (const auto& connection : connections) {
            if (IsPointOnConnection(connection.get(), adjustedPos)) {
                return connection.get();
            }
        }
        return nullptr;
    }
    
    bool IsPointOnConnection(Connection* connection, const POINT& point) {
        if (!connection) return false;
        
        POINT startPos = GetPortCenter(connection->outputPort);
        POINT endPos = GetPortCenter(connection->inputPort);
        
        // 베지어 곡선 상의 점들을 확인
        const int segments = 20;
        const double threshold = 10.0;
        
        int controlOffset = abs(endPos.x - startPos.x) / 2;
        POINT control1 = {startPos.x + controlOffset, startPos.y};
        POINT control2 = {endPos.x - controlOffset, endPos.y};
        
        for (int i = 0; i <= segments; i++) {
            float t = (float)i / segments;
            POINT bezierPoint = CalculateBezierPoint(startPos, control1, control2, endPos, t);
            
            double distance = sqrt(pow(point.x - bezierPoint.x, 2) + pow(point.y - bezierPoint.y, 2));
            if (distance <= threshold) {
                return true;
            }
        }
        
        return false;
    }
    
    void RemoveConnection(Connection* connection) {
        auto it = std::find_if(connections.begin(), connections.end(),
            [connection](const std::unique_ptr<Connection>& conn) { return conn.get() == connection; });
        
        if (it != connections.end()) {
            // 연결 제거 후 노드 리셋
            ResetNodeAfterDisconnection((*it)->inputPort->parentNode);
            connections.erase(it);
        }
    }
    
    void ResetNodeAfterDisconnection(Node* node) {
        if (!node) return;
        
        node->inputImageNames.clear();
        node->inputImages.clear();
        
        // 출력 연결이 없으면 출력 이미지도 제거 (Original 노드 제외)
        bool hasOutputConnection = false;
        for (const auto& connection : connections) {
            if (connection->outputPort->parentNode == node) {
                hasOutputConnection = true;
                break;
            }
        }
        
        if (!hasOutputConnection && node->type != NodeType::Original) {
            node->outputImageNames.clear();
            node->outputImages.clear();
        }
    }
    
    bool CanConnect(NodePort* port1, NodePort* port2) {
        if (!port1 || !port2) return false;
        if (port1->type == port2->type) return false;
        
        // 이미 연결되어 있는지 확인
        for (const auto& connection : connections) {
            if ((connection->outputPort == port1 && connection->inputPort == port2) ||
                (connection->outputPort == port2 && connection->inputPort == port1)) {
                return false;
            }
        }
        
        return true;
    }
    
	void ProcessImageFlow(NodePort* outputPort, NodePort* inputPort) {
        NodePort* fromPort = (outputPort->type == PortType::Output) ? outputPort : inputPort;
        NodePort* toPort = (outputPort->type == PortType::Input) ? outputPort : inputPort;
        
        Node* fromNode = fromPort->parentNode;
        Node* toNode = toPort->parentNode;
        
        ProcessSpecificNodeConnection(fromNode, toNode);
    }
    
    void ProcessSpecificNodeConnection(Node* fromNode, Node* toNode) {
        if (!fromNode || !toNode) return;
        
        switch (toNode->type) {
            case NodeType::Step01:
                if (fromNode->type == NodeType::Original) {
                    toNode->SetInputImagesFromNode(fromNode);
                    toNode->LoadImages({
                        "images/debug_full_mask.png",
                        "images/background.png", 
                        "images/output_no_bg.png"
                    });
                }
                break;
                
            case NodeType::Step02:
                if (fromNode->type == NodeType::Step01) {
                    if (fromNode->outputImageNames.size() >= 2) {
                        vector<string> selectedImageNames = {
                            fromNode->outputImageNames[0],
                            fromNode->outputImageNames[1]
                        };
                        vector<std::shared_ptr<Image>> selectedImages;
                        if (fromNode->outputImages.size() >= 2) {
                            selectedImages = {
                                fromNode->outputImages[0],
                                fromNode->outputImages[1]
                            };
                        }
                        
                        toNode->inputImageNames = selectedImageNames;
                        toNode->inputImages = selectedImages;
                        toNode->LoadImages({"images/lama_output.png"});
                    }
                }
                break;
                
            case NodeType::Step03:
                if (fromNode->type == NodeType::Original) {
                    toNode->SetInputImagesFromNode(fromNode);
                    
                    vector<string> combinedNames = fromNode->outputImageNames;
                    combinedNames.push_back("images/emoji_rabbit.png");
                    
                    toNode->LoadImages(combinedNames);
                    toNode->LoadImages({"images/output.png"});
                }
                break;
                
            case NodeType::Step04:
                if (fromNode->type == NodeType::Step01) {
                    if (fromNode->outputImageNames.size() >= 3) {
                        vector<string> selectedImageNames = {fromNode->outputImageNames[2]};
                        vector<std::shared_ptr<Image>> selectedImages;
                        if (fromNode->outputImages.size() >= 3) {
                            selectedImages = {fromNode->outputImages[2]};
                        }
                        
                        toNode->inputImageNames = selectedImageNames;
                        toNode->inputImages = selectedImages;
                        
                        toNode->LoadImages({
                            "images/360_view_001_000deg_from_000deg.png",
                            "images/360_view_002_045deg_from_060deg.png",
                            "images/360_view_003_090deg_from_090deg.png",
                            "images/360_view_004_135deg_from_090deg.png",
                            "images/360_view_005_180deg_from_180deg.png",
                            "images/360_view_006_225deg_from_240deg.png",
                            "images/360_view_007_270deg_from_270deg.png",
                            "images/360_view_008_315deg_from_000deg.png",
                            "images/ultrafast_360.gif"
                        });
                    }
                }
                break;
                
            case NodeType::Step05:
                if (fromNode->type == NodeType::Step04) {
                    if (fromNode->outputImageNames.size() >= 8) {
                        vector<string> selectedImageNames;
                        vector<std::shared_ptr<Image>> selectedImages;
                        
                        for (int i = 0; i < 8; i++) {
                            selectedImageNames.push_back(fromNode->outputImageNames[i]);
                            if (i < fromNode->outputImages.size()) {
                                selectedImages.push_back(fromNode->outputImages[i]);
                            }
                        }
                        
                        toNode->inputImageNames = selectedImageNames;
                        toNode->inputImages = selectedImages;
                        toNode->LoadImages({"images/step05_sc_2025-08-11.gif"});
                    }
                }
                break;
        }
    }
    
    void ClearAllConnections() {
        connections.clear();
        
        for (const auto& node : nodes) {
            if (node->type != NodeType::Original) {
                node->inputImageNames.clear();
                node->inputImages.clear();
                node->outputImageNames.clear();
                node->outputImages.clear();
            }
        }
        
        InvalidateRect(hwnd, NULL, FALSE);
    }
    
    void ResetAllNodes() {
        connections.clear();
        
        for (const auto& node : nodes) {
            node->inputImageNames.clear();
            node->inputImages.clear();
            node->outputImageNames.clear();
            node->outputImages.clear();
            
            if (node->type == NodeType::Original) {
                node->LoadImages({"images/input.png"});
            }
        }
        
        InvalidateRect(hwnd, NULL, FALSE);
    }
};

// 전역 변수
NodeCanvas* g_canvas = nullptr;
SimpleStatusBar* g_statusBar = nullptr;
ULONG_PTR g_gdiplusToken;

// GDI+ 초기화
void InitGDIPlus() {
    GdiplusStartupInput gdiplusStartupInput;
    GdiplusStartup(&g_gdiplusToken, &gdiplusStartupInput, NULL);
}

// GDI+ 정리
void ShutdownGDIPlus() {
    GdiplusShutdown(g_gdiplusToken);
}		
	
	
// 메뉴 아이템 ID
#define IDM_FILE_LOAD_IMAGE     1001
#define IDM_FILE_SAVE_ALL       1002
#define IDM_FILE_EXIT           1003
#define IDM_EDIT_CLEAR_CONN     1004
#define IDM_EDIT_RESET_NODES    1005
#define IDM_VIEW_RESET          1006
#define IDM_VIEW_FIT            1007
#define IDM_HELP_ABOUT          1008

// 메뉴 생성
HMENU CreateMainMenu() {
    HMENU hMenuBar = CreateMenu();
    
    // 파일 메뉴
    HMENU hFileMenu = CreatePopupMenu();
    AppendMenuW(hFileMenu, MF_STRING, IDM_FILE_LOAD_IMAGE, L"원본 이미지 로드");
    AppendMenuW(hFileMenu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(hFileMenu, MF_STRING, IDM_FILE_SAVE_ALL, L"모든 결과 저장");
    AppendMenuW(hFileMenu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(hFileMenu, MF_STRING, IDM_FILE_EXIT, L"종료");
    AppendMenuW(hMenuBar, MF_POPUP, (UINT_PTR)hFileMenu, L"파일");
    
    // 편집 메뉴
    HMENU hEditMenu = CreatePopupMenu();
    AppendMenuW(hEditMenu, MF_STRING, IDM_EDIT_CLEAR_CONN, L"모든 연결 제거");
    AppendMenuW(hEditMenu, MF_STRING, IDM_EDIT_RESET_NODES, L"모든 노드 리셋");
    AppendMenuW(hMenuBar, MF_POPUP, (UINT_PTR)hEditMenu, L"편집");
    
    // 보기 메뉴
    HMENU hViewMenu = CreatePopupMenu();
    AppendMenuW(hViewMenu, MF_STRING, IDM_VIEW_RESET, L"뷰 리셋");
    AppendMenuW(hViewMenu, MF_STRING, IDM_VIEW_FIT, L"화면에 맞춤");
    AppendMenuW(hMenuBar, MF_POPUP, (UINT_PTR)hViewMenu, L"보기");
    
    // 도움말 메뉴
    HMENU hHelpMenu = CreatePopupMenu();
    AppendMenuW(hHelpMenu, MF_STRING, IDM_HELP_ABOUT, L"정보");
    AppendMenuW(hMenuBar, MF_POPUP, (UINT_PTR)hHelpMenu, L"도움말");
    
    return hMenuBar;
}

// 메뉴 명령 처리
void HandleMenuCommand(HWND hwnd, WORD menuId) {
    switch (menuId) {
        case IDM_FILE_LOAD_IMAGE:
            MessageBoxW(hwnd, L"파일 로드 기능은 구현 예정입니다.", L"알림", MB_OK | MB_ICONINFORMATION);
            break;
            
        case IDM_FILE_SAVE_ALL:
            MessageBoxW(hwnd, L"파일 저장 기능은 구현 예정입니다.", L"알림", MB_OK | MB_ICONINFORMATION);
            break;
            
        case IDM_FILE_EXIT:
            PostMessage(hwnd, WM_CLOSE, 0, 0);
            break;
            
        case IDM_EDIT_CLEAR_CONN:
            if (MessageBoxW(hwnd, L"모든 연결을 제거하시겠습니까?", L"확인", 
                           MB_YESNO | MB_ICONQUESTION) == IDYES) {
                if (g_canvas) {
                    g_canvas->ClearAllConnections();
                    if (g_statusBar) {
                        g_statusBar->SetTextW(L"모든 연결이 제거되었습니다");
                    }
                }
            }
            break;
            
        case IDM_EDIT_RESET_NODES:
            if (MessageBoxW(hwnd, L"모든 노드를 초기 상태로 리셋하시겠습니까?", L"확인", 
                           MB_YESNO | MB_ICONQUESTION) == IDYES) {
                if (g_canvas) {
                    g_canvas->ResetAllNodes();
                    if (g_statusBar) {
                        g_statusBar->SetTextW(L"모든 노드가 리셋되었습니다");
                    }
                }
            }
            break;
            
        case IDM_VIEW_RESET:
        case IDM_VIEW_FIT:
            if (g_canvas) {
                InvalidateRect(hwnd, NULL, FALSE);
            }
            break;
            
        case IDM_HELP_ABOUT:
            {
                // 한글이 깨지지 않도록 유니코드 사용
                MessageBoxW(hwnd, 
                    L"이미지 처리 워크플로우 시스템 (GIF 지원 개선 버전)\n\n"
                    L"사용법:\n"
                    L"1. 노드를 드래그하여 이동\n"
                    L"2. 출력 포트에서 입력 포트로 연결\n"
                    L"3. 연결선을 우클릭하여 제거\n"
                    L"4. 마우스 휠로 확대/축소\n"
                    L"5. 가운데 버튼으로 캔버스 이동\n\n"
                    L"각 단계별로 이미지가 자동 처리됩니다.\n"
                    L"GIF 파일은 플레이스홀더로 표시됩니다.",
                    L"정보", MB_OK | MB_ICONINFORMATION);
            }
            break;
    }
}

// 윈도우 프로시저
LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
        case WM_CREATE:
            {
                // 메뉴 설정
                SetMenu(hwnd, CreateMainMenu());
                
                // 상태바 생성
                g_statusBar = new SimpleStatusBar(hwnd);
                
                g_canvas = new NodeCanvas(hwnd);
            }
            break;
            
        case WM_SIZE:
            {
                // 캔버스 더블 버퍼링 재설정
                if (g_canvas) {
                    g_canvas->OnResize();
                }
                InvalidateRect(hwnd, NULL, FALSE);
            }
            break;
            
        case WM_COMMAND:
            HandleMenuCommand(hwnd, LOWORD(wParam));
            break;
            
        case WM_PAINT:
            {
                PAINTSTRUCT ps;
                HDC hdc = BeginPaint(hwnd, &ps);
                
                if (g_canvas) {
                    g_canvas->OnPaint(hdc, g_statusBar);
                }
                
                EndPaint(hwnd, &ps);
            }
            break;
            
        case WM_LBUTTONDOWN:
            if (g_canvas) {
                g_canvas->OnMouseDown(LOWORD(lParam), HIWORD(lParam), wParam);
            }
            break;
            
        case WM_RBUTTONDOWN:
            if (g_canvas) {
                g_canvas->OnMouseDown(LOWORD(lParam), HIWORD(lParam), wParam);
            }
            break;
            
        case WM_MBUTTONDOWN:
            if (g_canvas) {
                g_canvas->OnMouseDown(LOWORD(lParam), HIWORD(lParam), wParam);
            }
            break;
            
        case WM_MOUSEMOVE:
            if (g_canvas) {
                g_canvas->OnMouseMove(LOWORD(lParam), HIWORD(lParam), wParam);
            }
            break;
            
        case WM_LBUTTONUP:
        case WM_RBUTTONUP:
        case WM_MBUTTONUP:
            if (g_canvas) {
                g_canvas->OnMouseUp(LOWORD(lParam), HIWORD(lParam), wParam);
            }
            break;
            
        case WM_MOUSEWHEEL:
            if (g_canvas) {
                g_canvas->OnMouseWheel(GET_WHEEL_DELTA_WPARAM(wParam));
            }
            break;
            
        case WM_DESTROY:
            if (g_canvas) {
                delete g_canvas;
                g_canvas = nullptr;
            }
            if (g_statusBar) {
                delete g_statusBar;
                g_statusBar = nullptr;
            }
            PostQuitMessage(0);
            break;
            
        default:
            return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    return 0;
}

// 메인 함수
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, 
                   LPSTR lpCmdLine, int nCmdShow) {
    
    // GDI+ 초기화
    InitGDIPlus();
    
    // 윈도우 클래스 등록
    WNDCLASSEX wc = {};
    wc.cbSize = sizeof(WNDCLASSEX);
    wc.style = CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS;
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"NodeEditorWindow";
    wc.hIconSm = LoadIcon(NULL, IDI_APPLICATION);
    
    if (!RegisterClassEx(&wc)) {
        MessageBoxW(NULL, L"윈도우 클래스 등록 실패!", L"오류", MB_OK | MB_ICONERROR);
        ShutdownGDIPlus();
        return -1;
    }
    
    // 윈도우 생성
    HWND hwnd = CreateWindowExW(
        0,
        L"NodeEditorWindow",
        L"이미지 처리 워크플로우 - Node Based UI (C++ with GDI+) - GIF 지원 개선",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT,
        1400, 900,
        NULL, NULL, hInstance, NULL
    );
    
    if (!hwnd) {
        MessageBoxW(NULL, L"윈도우 생성 실패!", L"오류", MB_OK | MB_ICONERROR);
        ShutdownGDIPlus();
        return -1;
    }
    
    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);
    
    // 메시지 루프
    MSG msg = {};
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    
    // GDI+ 정리
    ShutdownGDIPlus();
    
    return (int)msg.wParam;
}