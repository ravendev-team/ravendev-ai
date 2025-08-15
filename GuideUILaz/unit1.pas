unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,
  StdCtrls, ComCtrls, Types, FPImage, FPCanvas, IntfGraphics, GraphType,
  LCLType, LCLIntf, Math, Generics.Collections;

type
  TNodeType = (ntOriginal, ntStep01, ntStep02, ntStep03, ntStep04, ntStep05);
  TPortType = (ptInput, ptOutput);

  // Forward declarations
  TNode = class;
  TNodePort = class;
  TConnection = class;
  TNodeCanvas = class;

  { TNodePort }
  TNodePort = class
  private
    FName: string;
    FPortType: TPortType;
    FParentNode: TNode;
    FBounds: TRect;
  public
    constructor Create(const AName: string; APortType: TPortType; AParentNode: TNode);
    property Name: string read FName write FName;
    property PortType: TPortType read FPortType write FPortType;
    property ParentNode: TNode read FParentNode write FParentNode;
    property Bounds: TRect read FBounds write FBounds;
  end;

  { TNode }
  TNode = class
  private
    FTitle: string;
    FPosition: TPoint;
    FInputPorts: specialize TList<TNodePort>;
    FOutputPorts: specialize TList<TNodePort>;
    FInputImages: specialize TList<TImage>;
    FOutputImages: specialize TList<TImage>;
    FInputImageNames: TStringList;
    FOutputImageNames: TStringList;
    FNodeType: TNodeType;
  public
    constructor Create(const ATitle: string; APosition: TPoint; ANodeType: TNodeType);
    destructor Destroy; override;

    procedure LoadImages(const ImageFileNames: array of string; IsInput: Boolean = True);
    procedure SetInputImages(Images: specialize TList<TImage>; ImageNames: TStringList);
    function CreatePlaceholderImage(const FileName: string; BackgroundColor: TColor): TImage;
    function GetPlaceholderColor(const FileName: string): TColor;

    property Title: string read FTitle write FTitle;
    property Position: TPoint read FPosition write FPosition;
    property InputPorts: specialize TList<TNodePort> read FInputPorts;
    property OutputPorts: specialize TList<TNodePort> read FOutputPorts;
    property InputImages: specialize TList<TImage> read FInputImages;
    property OutputImages: specialize TList<TImage> read FOutputImages;
    property InputImageNames: TStringList read FInputImageNames;
    property OutputImageNames: TStringList read FOutputImageNames;
    property NodeType: TNodeType read FNodeType write FNodeType;
  end;

  { TConnection }
  TConnection = class
  private
    FOutputPort: TNodePort;
    FInputPort: TNodePort;
  public
    constructor Create(AOutputPort, AInputPort: TNodePort);
    property OutputPort: TNodePort read FOutputPort write FOutputPort;
    property InputPort: TNodePort read FInputPort write FInputPort;
  end;

  { TNodeCanvas }
  TNodeCanvas = class(TCustomControl)
  private
    FNodes: specialize TList<TNode>;
    FConnections: specialize TList<TConnection>;
    FDraggedNode: TNode;
    FConnectionStartPort: TNodePort;
    FLastMousePos: TPoint;
    FCanvasOffset: TPoint;
    FIsPanning: Boolean;
    FZoomLevel: Double;
    FAnimationTimer: TTimer;

    procedure InitializeComponent;
    procedure AddProcessingNodes;

    // Event handlers
    procedure NodeCanvas_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure NodeCanvas_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure NodeCanvas_MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure NodeCanvas_Paint(Sender: TObject);
    function NodeCanvas_MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
    procedure AnimationTimerTick(Sender: TObject);

    // Drawing methods
    procedure DrawGrid(gCanvas: TCanvas);
    procedure DrawNode(gCanvas: TCanvas; Node: TNode);
    procedure DrawNodeImages(gCanvas: TCanvas; Node: TNode; const NodeRect: TRect);
    procedure DrawNodePorts(gCanvas: TCanvas; Node: TNode; const NodeRect: TRect);
    procedure DrawPort(gCanvas: TCanvas; Port: TNodePort; const Position: TPoint);
    procedure DrawConnection(gCanvas: TCanvas; Connection: TConnection);
    procedure DrawTempConnection(gCanvas: TCanvas; StartPort: TNodePort; const MousePos: TPoint);
    procedure DrawBezierConnection(gCanvas: TCanvas; const StartPos, EndPos: TPoint;
                                  AColor: TColor; LineWidth: Integer = 3);

    // Utility methods
    function GetNodeWidth(Node: TNode): Integer;
    function GetNodeHeight(Node: TNode): Integer;
    function GetNodeColor(NodeType: TNodeType): TColor;
    function GetPortCenter(Port: TNodePort): TPoint;
    function GetNodeAtPosition(const Position: TPoint): TNode;
    function GetPortAtPosition(const Position: TPoint): TNodePort;
    function GetConnectionAtPosition(const Position: TPoint): TConnection;
    function IsPointOnConnection(Connection: TConnection; const Point: TPoint): Boolean;
    function IsConnectionNearMouse(Connection: TConnection; const MousePos: TPoint): Boolean;
    function CalculateBezierPoint(const P0, P1, P2, P3: TPoint; t: Double): TPoint;
    function CanConnect(Port1, Port2: TNodePort): Boolean;

    // Processing methods
    procedure ProcessImageFlow(OutputPort, InputPort: TNodePort);
    procedure ProcessSpecificNodeConnection(FromNode, ToNode: TNode);
    procedure RemoveConnection(Connection: TConnection);
    procedure ResetNodeAfterDisconnection(Node: TNode);
    procedure UpdateStatusMessage(const Message: string);

  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ClearAllConnections;
    procedure ResetAllNodes;

    property Nodes: specialize TList<TNode> read FNodes;
    property Connections: specialize TList<TConnection> read FConnections;
  end;

  { TForm1 }
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    StatusBar1: TStatusBar;
    FileMenu: TMenuItem;
    LoadImageItem: TMenuItem;
    SaveAllItem: TMenuItem;
    ExitItem: TMenuItem;
    EditMenu: TMenuItem;
    ClearAllConnectionsItem: TMenuItem;
    ResetAllNodesItem: TMenuItem;
    ViewMenu: TMenuItem;
    ResetViewItem: TMenuItem;
    FitToScreenItem: TMenuItem;
    HelpMenu: TMenuItem;
    AboutItem: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);  // 추가 : 프로그램 종료시 메모리 오류 방지를 위해
    procedure LoadImageItemClick(Sender: TObject);
    procedure SaveAllItemClick(Sender: TObject);
    procedure ClearAllConnectionsItemClick(Sender: TObject);
    procedure ResetAllNodesItemClick(Sender: TObject);
    procedure ResetViewItemClick(Sender: TObject);
    procedure FitToScreenItemClick(Sender: TObject);
    procedure AboutItemClick(Sender: TObject);
    procedure ExitItemClick(Sender: TObject);

  private
    FCanvas: TNodeCanvas;
    procedure InitUI;
    procedure CreateMenus;      // 추가
    procedure CreateStatusBar;  // 추가
    procedure CleanupBeforeClose;  // 추가

  public

  end;

// Helper functions
procedure FillRoundedRectangle(gCanvas: TCanvas; const Rect: TRect; Radius: Integer; Color: TColor);
procedure DrawRoundedRectangle(gCanvas: TCanvas; const Rect: TRect; Radius: Integer; PenColor: TColor);
function ExtractFilenameOnlyWithoutExt(const AFileName: String): String;
function gTextWidth(const AText: String; AFont: TFont): Integer;
function gTextHeight(const AText: String; AFont: TFont): Integer;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ Helper functions }

function ExtractFilenameOnlyWithoutExt(const AFileName: String): String;
begin
  Result := ChangeFileExt(ExtractFileName(AFileName), '');
end;

function gTextWidth(const AText: String; AFont: TFont): Integer;
var
  bmp: TBitmap;
begin
  Result := 0;
  bmp := TBitmap.Create;
  try
    bmp.Canvas.Font.Assign(AFont);
    Result := bmp.Canvas.TextWidth(AText);
  finally
    bmp.Free;
  end;
end;

function gTextHeight(const AText: String; AFont: TFont): Integer;
var
  bmp: TBitmap;
begin
  Result := 0;
  bmp := TBitmap.Create;
  try
    bmp.Canvas.Font.Assign(AFont);
    Result := bmp.Canvas.TextHeight(AText);
  finally
    bmp.Free;
  end;
end;


procedure FillRoundedRectangle(gCanvas: TCanvas; const Rect: TRect; Radius: Integer; Color: TColor);
begin
  gCanvas.Brush.Color := Color;
  gCanvas.Pen.Color := Color;
  gCanvas.RoundRect(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom, Radius, Radius);
end;


procedure DrawRoundedRectangle(gCanvas: TCanvas; const Rect: TRect; Radius: Integer; PenColor: TColor);
begin
  gCanvas.Brush.Style := bsClear;
  gCanvas.Pen.Color := PenColor;
  gCanvas.Pen.Width := 2;
  gCanvas.RoundRect(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom, Radius, Radius);
end;

{ TNodePort }

constructor TNodePort.Create(const AName: string; APortType: TPortType; AParentNode: TNode);
begin
  FName := AName;
  FPortType := APortType;
  FParentNode := AParentNode;
end;

{ TNode }

constructor TNode.Create(const ATitle: string; APosition: TPoint; ANodeType: TNodeType);
begin
  FTitle := ATitle;
  FPosition := APosition;
  FNodeType := ANodeType;
  FInputPorts := specialize TList<TNodePort>.Create;
  FOutputPorts := specialize TList<TNodePort>.Create;
  FInputImages := specialize TList<TImage>.Create;
  FOutputImages := specialize TList<TImage>.Create;
  FInputImageNames := TStringList.Create;
  FOutputImageNames := TStringList.Create;
end;


destructor TNode.Destroy;
var
  i: Integer;
begin
  // Clean up input images first
  if Assigned(FInputImages) then
  begin
    for i := FInputImages.Count - 1 downto 0 do
    begin
      if Assigned(FInputImages[i]) then
      begin
        FInputImages[i].Free;
        FInputImages[i] := nil;
      end;
    end;
    FInputImages.Clear;
    FInputImages.Free;
    FInputImages := nil;
  end;

  // Clean up output images
  if Assigned(FOutputImages) then
  begin
    for i := FOutputImages.Count - 1 downto 0 do
    begin
      if Assigned(FOutputImages[i]) then
      begin
        FOutputImages[i].Free;
        FOutputImages[i] := nil;
      end;
    end;
    FOutputImages.Clear;
    FOutputImages.Free;
    FOutputImages := nil;
  end;

  // Clean up ports
  if Assigned(FInputPorts) then
  begin
    for i := FInputPorts.Count - 1 downto 0 do
    begin
      if Assigned(FInputPorts[i]) then
      begin
        FInputPorts[i].Free;
        FInputPorts[i] := nil;
      end;
    end;
    FInputPorts.Clear;
    FInputPorts.Free;
    FInputPorts := nil;
  end;

  if Assigned(FOutputPorts) then
  begin
    for i := FOutputPorts.Count - 1 downto 0 do
    begin
      if Assigned(FOutputPorts[i]) then
      begin
        FOutputPorts[i].Free;
        FOutputPorts[i] := nil;
      end;
    end;
    FOutputPorts.Clear;
    FOutputPorts.Free;
    FOutputPorts := nil;
  end;

  if Assigned(FInputImageNames) then
  begin
    FInputImageNames.Free;
    FInputImageNames := nil;
  end;

  if Assigned(FOutputImageNames) then
  begin
    FOutputImageNames.Free;
    FOutputImageNames := nil;
  end;

  inherited Destroy;
end;



procedure TNode.LoadImages(const ImageFileNames: array of string; IsInput: Boolean);
var
  Images: specialize TList<TImage>;
  ImageNames: TStringList;
  FileName: string;
  Image: TImage;
  PlaceholderColor: TColor;
  i: Integer;
begin
  if IsInput then
  begin
    Images := FInputImages;
    ImageNames := FInputImageNames;
  end
  else
  begin
    Images := FOutputImages;
    ImageNames := FOutputImageNames;
  end;

  // Clear existing images
  for i := 0 to Images.Count - 1 do
  begin
    if Assigned(Images[i]) then
      Images[i].Free;
  end;

  Images.Clear;
  ImageNames.Clear;

  for i := 0 to Length(ImageFileNames) - 1 do
  begin
    FileName := ImageFileNames[i];
    Image := nil;
    try
      if FileExists(FileName) then
      begin
        Image := TImage.Create(nil);
        try
          Image.Picture.LoadFromFile(FileName);
        except
          Image.Free;
          Image := nil;
          PlaceholderColor := GetPlaceholderColor(FileName);
          Image := CreatePlaceholderImage(FileName, PlaceholderColor);
        end;
      end
      else
      begin
        PlaceholderColor := GetPlaceholderColor(FileName);
        Image := CreatePlaceholderImage(FileName, PlaceholderColor);
      end;

      Images.Add(Image);
      ImageNames.Add(FileName);
    except
      on E: Exception do
      begin
        if Assigned(Image) then
          Image.Free;
        WriteLn('이미지 로드에 실패: ', FileName, ' - ', E.Message);
        Image := CreatePlaceholderImage('ERROR: ' + ExtractFileName(FileName), clRed);
        Images.Add(Image);
        ImageNames.Add(FileName);
      end;
    end;
  end;
end;




procedure TNode.SetInputImages(Images: specialize TList<TImage>; ImageNames: TStringList);
var
  i: Integer;
begin
  // Clear existing - but don't free the images as they're owned elsewhere
  if Assigned(FInputImages) then
    FInputImages.Clear;
  if Assigned(FInputImageNames) then
    FInputImageNames.Clear;

  if Assigned(Images) then
  begin
    for i := 0 to Images.Count - 1 do
      FInputImages.Add(Images[i]);
  end;

  if Assigned(ImageNames) then
    FInputImageNames.AddStrings(ImageNames);
end;




function TNode.GetPlaceholderColor(const FileName: string): TColor;
var
  LowerFileName: string;
begin
  LowerFileName := LowerCase(FileName);

  if Pos('input', LowerFileName) > 0 then
    Result := clSkyBlue
  else if Pos('mask', LowerFileName) > 0 then
    Result := clPurple
  else if Pos('background', LowerFileName) > 0 then
    Result := clLime
  else if Pos('output', LowerFileName) > 0 then
    Result := TColor($00A5FF)
  else if Pos('lama', LowerFileName) > 0 then
    Result := clAqua
  else if Pos('emoji', LowerFileName) > 0 then
    Result := clYellow
  else if Pos('360', LowerFileName) > 0 then
    Result := clFuchsia
  else if Pos('gif', LowerFileName) > 0 then
    Result := TColor($FF00FF)
  else if Pos('step05', LowerFileName) > 0 then
    Result := TColor($32CD32)
  else
    Result := clGray;
end;


function TNode.CreatePlaceholderImage(const FileName: string; BackgroundColor: TColor): TImage;
var
  image: TBitmap;
  displayName: string;
  tWidth: Integer;
  tHeight: Integer;
  X, Y: Integer;
begin
  Result := TImage.Create(nil);
  image := TBitmap.Create;
  try
    image.SetSize(100, 80);

    with image.Canvas do
    begin
      Brush.Color := BackgroundColor;
      FillRect(0, 0, 100, 80);

      Font.Name := 'Arial';
      Font.Size := 7;
      Font.Style := [fsBold];
      Font.Color := clBlack;

      displayName := ExtractFilenameOnlyWithoutExt(FileName);
      if Length(displayName) > 15 then
        displayName := Copy(displayName, 1, 15) + '...';

      tWidth := gTextWidth(displayName, Font);
      tHeight := gTextHeight(displayName, Font);

      X := Max(2, (100 - tWidth) div 2);
      Y := Max(2, (80 - tHeight) div 2);

      TextOut(X, Y, displayName);

      Pen.Color := clBlack;
      Rectangle(0, 0, 100, 80);
    end;

    Result.Picture.Bitmap := image;
  finally
    // image ownership transferred to TImage
  end;
end;




{ TConnection }

constructor TConnection.Create(AOutputPort, AInputPort: TNodePort);
begin
  if (AOutputPort.PortType = ptOutput) and (AInputPort.PortType = ptInput) then
  begin
    FOutputPort := AOutputPort;
    FInputPort := AInputPort;
  end
  else
  begin
    if AInputPort.PortType = ptOutput then
      FOutputPort := AInputPort
    else
      FOutputPort := AOutputPort;

    if AInputPort.PortType = ptInput then
      FInputPort := AInputPort
    else
      FInputPort := AOutputPort;
  end;
end;

{ TNodeCanvas }

constructor TNodeCanvas.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FNodes := specialize TList<TNode>.Create;
  FConnections := specialize TList<TConnection>.Create;
  FDraggedNode := nil;
  FConnectionStartPort := nil;
  FCanvasOffset := Point(0, 0);
  FIsPanning := False;
  FZoomLevel := 1.0;

  InitializeComponent;

  // Animation timer setup
  FAnimationTimer := TTimer.Create(Self);
  FAnimationTimer.Interval := 50;
  FAnimationTimer.OnTimer := @AnimationTimerTick;
  FAnimationTimer.Enabled := True;

  AddProcessingNodes;
end;


// 프로그램 종료시에 각 노드에 이미지들이 로딩된 상태에서 종료되면
// 메모리 오류발생되어서 수정.
destructor TNodeCanvas.Destroy;
var
  i, j: Integer;
  Node: TNode;
begin
  // Stop timer first
  if Assigned(FAnimationTimer) then
  begin
    FAnimationTimer.Enabled := False;
    FAnimationTimer.Free;
    FAnimationTimer := nil;
  end;

  // Clean up all loaded images in nodes before destroying nodes
  if Assigned(FNodes) then
  begin
    for i := 0 to FNodes.Count - 1 do
    begin
      Node := FNodes[i];
      if Assigned(Node) then
      begin
        // Clear input images
        if Assigned(Node.InputImages) then
        begin
          for j := 0 to Node.InputImages.Count - 1 do
          begin
            if Assigned(Node.InputImages[j]) then
              Node.InputImages[j].Free;
          end;
          Node.InputImages.Clear;
        end;

        // Clear output images
        if Assigned(Node.OutputImages) then
        begin
          for j := 0 to Node.OutputImages.Count - 1 do
          begin
            if Assigned(Node.OutputImages[j]) then
              Node.OutputImages[j].Free;
          end;
          Node.OutputImages.Clear;
        end;

        // Clear image names
        if Assigned(Node.InputImageNames) then
          Node.InputImageNames.Clear;
        if Assigned(Node.OutputImageNames) then
          Node.OutputImageNames.Clear;
      end;
    end;
  end;

  // Clean up connections first
  if Assigned(FConnections) then
  begin
    for i := 0 to FConnections.Count - 1 do
      if Assigned(FConnections[i]) then
        FConnections[i].Free;
    FConnections.Free;
    FConnections := nil;
  end;

  // Clean up nodes
  if Assigned(FNodes) then
  begin
    for i := 0 to FNodes.Count - 1 do
      if Assigned(FNodes[i]) then
        FNodes[i].Free;
    FNodes.Free;
    FNodes := nil;
  end;

  inherited Destroy;
end;


procedure TNodeCanvas.InitializeComponent;
begin
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  Color := RGBToColor(45, 45, 48);
  SetBounds(0, 0, 1200, 800);
end;


procedure TNodeCanvas.AddProcessingNodes;
var
  OriginalNode, Step01Node, Step02Node, Step03Node, Step04Node, Step05Node: TNode;
begin
  // Original image node
  OriginalNode := TNode.Create('원본이미지', Point(50, 30), ntOriginal);
  OriginalNode.OutputPorts.Add(TNodePort.Create('Output', ptOutput, OriginalNode));
  OriginalNode.LoadImages(['images/input.png'], False);
  FNodes.Add(OriginalNode);

  // Step01 node
  Step01Node := TNode.Create('Step01', Point(300, 30), ntStep01);
  Step01Node.InputPorts.Add(TNodePort.Create('Input', ptInput, Step01Node));
  Step01Node.OutputPorts.Add(TNodePort.Create('Output', ptOutput, Step01Node));
  FNodes.Add(Step01Node);

  // Step02 node
  Step02Node := TNode.Create('Step02', Point(600, 30), ntStep02);
  Step02Node.InputPorts.Add(TNodePort.Create('Input', ptInput, Step02Node));
  Step02Node.OutputPorts.Add(TNodePort.Create('Output', ptOutput, Step02Node));
  FNodes.Add(Step02Node);

  // Step03 node
  Step03Node := TNode.Create('Step03', Point(300, 330), ntStep03);
  Step03Node.InputPorts.Add(TNodePort.Create('Input', ptInput, Step03Node));
  Step03Node.OutputPorts.Add(TNodePort.Create('Output', ptOutput, Step03Node));
  FNodes.Add(Step03Node);

  // Step04 node
  Step04Node := TNode.Create('Step04', Point(600, 330), ntStep04);
  Step04Node.InputPorts.Add(TNodePort.Create('Input', ptInput, Step04Node));
  Step04Node.OutputPorts.Add(TNodePort.Create('Output', ptOutput, Step04Node));
  FNodes.Add(Step04Node);

  // Step05 node
  Step05Node := TNode.Create('Step05', Point(900, 330), ntStep05);
  Step05Node.InputPorts.Add(TNodePort.Create('Input', ptInput, Step05Node));
  Step05Node.OutputPorts.Add(TNodePort.Create('Output', ptOutput, Step05Node));
  FNodes.Add(Step05Node);
end;



procedure TNodeCanvas.AnimationTimerTick(Sender: TObject);
begin
  Invalidate;
end;


// Override methods for proper event handling
procedure TNodeCanvas.Paint;
begin
  NodeCanvas_Paint(Self);
end;


procedure TNodeCanvas.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);  // 상속받음
  NodeCanvas_MouseDown(Self, Button, Shift, X, Y);
end;


procedure TNodeCanvas.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y); // 상속받음
  NodeCanvas_MouseMove(Self, Shift, X, Y);
end;


procedure TNodeCanvas.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);  // 상속받음
  NodeCanvas_MouseUp(Self, Button, Shift, X, Y);
end;



function TNodeCanvas.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := NodeCanvas_MouseWheel(Self, Shift, WheelDelta, MousePos);
  if not Result then
    Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos); // 상속받음
end;


procedure TNodeCanvas.NodeCanvas_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ClickedConnection: TConnection;
  ClickedPort: TNodePort;
  ClickedNode: TNode;
begin
  FLastMousePos := Point(X, Y);

  // 다른 상호작용 상태 초기화
  FDraggedNode := nil;

  if Button = mbMiddle then
  begin
    FIsPanning := True;
    Exit;
  end;

  // Right click to remove connection
  if Button = mbRight then
  begin
    ClickedConnection := GetConnectionAtPosition(Point(X, Y));
    if Assigned(ClickedConnection) then
    begin
      RemoveConnection(ClickedConnection);
      Invalidate;
      Exit;
    end;

    // Cancel connection creation
    if Assigned(FConnectionStartPort) then
    begin
      FConnectionStartPort := nil;
      Invalidate;
      Exit;
    end;
  end;

  if Button = mbLeft then
  begin
    // 포트 클릭 우선 확인 (포트가 노드보다 작으므로 먼저 체크)
    ClickedPort := GetPortAtPosition(Point(X, Y));
    if Assigned(ClickedPort) then
    begin
      if not Assigned(FConnectionStartPort) then
      begin
        FConnectionStartPort := ClickedPort;
      end
      else
      begin
        // Create connection
        if CanConnect(FConnectionStartPort, ClickedPort) then
        begin
          FConnections.Add(TConnection.Create(FConnectionStartPort, ClickedPort));
          ProcessImageFlow(FConnectionStartPort, ClickedPort);
        end;
        FConnectionStartPort := nil;
      end;
      Invalidate;
      Exit;
    end;

    // 포트가 아니면 노드 클릭 확인
    ClickedNode := GetNodeAtPosition(Point(X, Y));
    if Assigned(ClickedNode) then
    begin
      FDraggedNode := ClickedNode;

      // 클릭된 노드를 맨 앞으로 이동 (그리기 순서)
      FNodes.Remove(FDraggedNode);
      FNodes.Add(FDraggedNode);

      // 드래그 시작 위치 저장 (좌표 변환 적용)
      FLastMousePos := Point(X, Y);

      Invalidate;
    end;
  end;
end;




procedure TNodeCanvas.NodeCanvas_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  DeltaX, DeltaY: Integer;
begin
  if FIsPanning then
  begin
    FCanvasOffset.X := FCanvasOffset.X + X - FLastMousePos.X;
    FCanvasOffset.Y := FCanvasOffset.Y + Y - FLastMousePos.Y;
    FLastMousePos := Point(X, Y);
    Invalidate;
  end
  else if Assigned(FDraggedNode) then
  begin
    // 마우스 이동량 계산
    DeltaX := X - FLastMousePos.X;
    DeltaY := Y - FLastMousePos.Y;

    // 줌 레벨을 고려한 실제 이동량
    DeltaX := Round(DeltaX / FZoomLevel);
    DeltaY := Round(DeltaY / FZoomLevel);

    // 노드 위치 업데이트
    FDraggedNode.Position := Point(
      FDraggedNode.Position.X + DeltaX,
      FDraggedNode.Position.Y + DeltaY
    );

    FLastMousePos := Point(X, Y);
    Invalidate;
  end
  else if Assigned(FConnectionStartPort) then
  begin
    FLastMousePos := Point(X, Y);
    Invalidate;
  end
  else
  begin
    // 단순히 마우스 위치만 업데이트
    FLastMousePos := Point(X, Y);
  end;
end;



procedure TNodeCanvas.NodeCanvas_MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    if Assigned(FDraggedNode) then
    begin
      FDraggedNode := nil;
      Invalidate;
    end;
  end
  else if Button = mbMiddle then
  begin
    FIsPanning := False;
  end;
end;


function TNodeCanvas.NodeCanvas_MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
var
  OldZoom: Double;
begin
  Result := True;
  OldZoom := FZoomLevel;

  if WheelDelta > 0 then
    FZoomLevel := FZoomLevel + 0.1
  else
    FZoomLevel := FZoomLevel - 0.1;

  FZoomLevel := Max(0.1, Min(3.0, FZoomLevel));

  if OldZoom <> FZoomLevel then
    Invalidate;
end;


procedure TNodeCanvas.NodeCanvas_Paint(Sender: TObject);
var
  i: Integer;
  Connection: TConnection;
  Node: TNode;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  DrawGrid(Canvas);

  // Draw connections
  for i := 0 to FConnections.Count - 1 do
  begin
    Connection := FConnections[i];
    DrawConnection(Canvas, Connection);
  end;

  // Draw temporary connection
  if Assigned(FConnectionStartPort) then
    DrawTempConnection(Canvas, FConnectionStartPort, FLastMousePos);

  // Draw nodes
  for i := 0 to FNodes.Count - 1 do
  begin
    Node := FNodes[i];
    DrawNode(Canvas, Node);
  end;
end;

procedure TNodeCanvas.DrawGrid(gCanvas: TCanvas);
var
  GridSize, StartX, StartY, X, Y: Integer;
begin
  gCanvas.Pen.Color := RGBToColor(60, 60, 63);
  gCanvas.Pen.Width := 1;

  GridSize := 20;
  StartX := -(FCanvasOffset.X mod GridSize);
  StartY := -(FCanvasOffset.Y mod GridSize);

  X := StartX;
  while X < Width do
  begin
    gCanvas.Line(X, 0, X, Height);
    Inc(X, GridSize);
  end;

  Y := StartY;
  while Y < Height do
  begin
    gCanvas.Line(0, Y, Width, Y);
    Inc(Y, GridSize);
  end;
end;

function TNodeCanvas.GetNodeWidth(Node: TNode): Integer;
var
  MaxImages, ImagesPerRow: Integer;
begin
  MaxImages := Max(Node.InputImages.Count, Node.OutputImages.Count);
  ImagesPerRow := Min(4, MaxImages);
  Result := Max(200, 20 + ImagesPerRow * 65);
end;

function TNodeCanvas.GetNodeHeight(Node: TNode): Integer;
var
  InputRows, OutputRows, BaseHeight, ImageHeight: Integer;
begin
  if Assigned(Node.InputImages) then
    InputRows := (Node.InputImages.Count - 1) div 4 + 1
  else
    InputRows := 0;

  if Assigned(Node.OutputImages) then
    OutputRows := (Node.OutputImages.Count - 1) div 4 + 1
  else
    OutputRows := 0;

  BaseHeight := 80;
  ImageHeight := (InputRows + OutputRows) * 80;

  if InputRows > 0 then Inc(ImageHeight, 20);
  if OutputRows > 0 then Inc(ImageHeight, 20);

  Result := Max(BaseHeight, BaseHeight + ImageHeight);
end;

function TNodeCanvas.GetNodeColor(NodeType: TNodeType): TColor;
begin
  case NodeType of
    ntOriginal: Result := RGBToColor(70, 130, 180);
    ntStep01: Result := RGBToColor(220, 20, 60);
    ntStep02: Result := RGBToColor(255, 140, 0);
    ntStep03: Result := RGBToColor(50, 205, 50);
    ntStep04: Result := RGBToColor(138, 43, 226);
    ntStep05: Result := RGBToColor(255, 20, 147);
    else Result := RGBToColor(70, 70, 74);
  end;
end;

procedure TNodeCanvas.DrawNode(gCanvas: TCanvas; Node: TNode);
var
  NodeWidth, NodeHeight: Integer;
  NodeRect: TRect;
  NodeColor: TColor;
  TitleRect: TRect;
  TextStyle: TTextStyle;
begin
  NodeWidth := GetNodeWidth(Node);
  NodeHeight := GetNodeHeight(Node);
  NodeRect := Rect(Node.Position.X, Node.Position.Y,
                   Node.Position.X + NodeWidth, Node.Position.Y + NodeHeight);

  NodeColor := GetNodeColor(Node.NodeType);

  // Fill rounded rectangle
  FillRoundedRectangle(gCanvas, NodeRect, 8, NodeColor);

  // Draw border
  DrawRoundedRectangle(gCanvas, NodeRect, 8, RGB(150, 150, 154));

  // Draw title
  gCanvas.Font.Name := 'Segoe UI';
  gCanvas.Font.Size := 11;
  gCanvas.Font.Style := [fsBold];
  gCanvas.Font.Color := clWhite;
  gCanvas.Brush.Style := bsClear;

  TitleRect := Rect(NodeRect.Left, NodeRect.Top + 8,
                    NodeRect.Right, NodeRect.Top + 33);

  // TextStyle 설정
  TextStyle := gCanvas.TextStyle;
  TextStyle.Alignment := taCenter;
  TextStyle.Layout := tlCenter;
  TextStyle.SingleLine := True;

  gCanvas.TextRect(TitleRect, TitleRect.Left, TitleRect.Top, Node.Title, TextStyle);

  DrawNodeImages(gCanvas, Node, NodeRect);
  DrawNodePorts(gCanvas, Node, NodeRect);
end;

procedure TNodeCanvas.DrawNodeImages(gCanvas: TCanvas; Node: TNode; const NodeRect: TRect);
var
  ImageY, ImageSize, Spacing, i, Row, Col, X, Y: Integer;
  ImgRect: TRect;
  Image: TImage;
  ImageName: string;
begin
  ImageY := NodeRect.Top + 35;
  ImageSize := 60;
  Spacing := 5;

  // Draw input images
  if Assigned(Node.InputImages) and (Node.InputImages.Count > 0) then
  begin
    gCanvas.Font.Size := 8;
    gCanvas.Font.Style := [fsBold];
    gCanvas.Font.Color := clSkyBlue;
    gCanvas.TextOut(NodeRect.Left + 10, ImageY - 15, 'INPUT');

    for i := 0 to Node.InputImages.Count - 1 do
    begin
      Row := i div 4;
      Col := i mod 4;

      X := NodeRect.Left + 10 + Col * (ImageSize + Spacing);
      Y := ImageY + Row * (ImageSize + Spacing);

      ImgRect := Rect(X, Y, X + ImageSize, Y + ImageSize);

      if Assigned(Node.InputImages[i]) then
      begin
        Image := Node.InputImages[i];
        if Assigned(Image.Picture.Bitmap) then
          gCanvas.StretchDraw(ImgRect, Image.Picture.Bitmap);

        if i < Node.InputImageNames.Count then
        begin
          ImageName := Node.InputImageNames[i];
          gCanvas.Font.Size := 6;
          gCanvas.Font.Color := clWhite;
          gCanvas.TextOut(X, Y + ImageSize + 2, ExtractFilenameOnlyWithoutExt(ImageName));
        end;
      end
      else
      begin
        gCanvas.Brush.Color := clGray;
        gCanvas.FillRect(ImgRect);
        gCanvas.Pen.Color := clSilver;
        gCanvas.Rectangle(ImgRect);
      end;
    end;

    Inc(ImageY, ((Node.InputImages.Count - 1) div 4 + 1) * (ImageSize + Spacing) + 20);
  end;

  // Draw output images
  if Assigned(Node.OutputImages) and (Node.OutputImages.Count > 0) then
  begin
    gCanvas.Font.Size := 8;
    gCanvas.Font.Style := [fsBold];
    gCanvas.Font.Color := TColor($00A5FF);
    gCanvas.TextOut(NodeRect.Left + 10, ImageY - 15, 'OUTPUT');

    for i := 0 to Node.OutputImages.Count - 1 do
    begin
      Row := i div 4;
      Col := i mod 4;

      X := NodeRect.Left + 10 + Col * (ImageSize + Spacing);
      Y := ImageY + Row * (ImageSize + Spacing);

      ImgRect := Rect(X, Y, X + ImageSize, Y + ImageSize);

      if Assigned(Node.OutputImages[i]) then
      begin
        Image := Node.OutputImages[i];
        if Assigned(Image.Picture.Bitmap) then
          gCanvas.StretchDraw(ImgRect, Image.Picture.Bitmap);

        if i < Node.OutputImageNames.Count then
        begin
          ImageName := Node.OutputImageNames[i];
          gCanvas.Font.Size := 6;
          gCanvas.Font.Color := clWhite;
          gCanvas.TextOut(X, Y + ImageSize + 2, ExtractFilenameOnlyWithoutExt(ImageName));
        end;
      end
      else
      begin
        gCanvas.Brush.Color := clGray;
        gCanvas.FillRect(ImgRect);
        gCanvas.Pen.Color := clSilver;
        gCanvas.Rectangle(ImgRect);
      end;
    end;
  end;
end;

procedure TNodeCanvas.DrawNodePorts(gCanvas: TCanvas; Node: TNode; const NodeRect: TRect);
var
  PortY: Integer;
  Port: TNodePort;
  TextWidth: Integer;
  i: Integer;
begin
  PortY := NodeRect.Bottom - 30;

  // Draw input ports
  for i := 0 to Node.InputPorts.Count - 1 do
  begin
    Port := Node.InputPorts[i];
    DrawPort(gCanvas, Port, Point(NodeRect.Left - 8, PortY));

    gCanvas.Font.Size := 9;
    gCanvas.Font.Color := clSilver;
    gCanvas.TextOut(NodeRect.Left + 15, PortY - 8, Port.Name);
  end;

  // Draw output ports
  for i := 0 to Node.OutputPorts.Count - 1 do
  begin
    Port := Node.OutputPorts[i];
    DrawPort(gCanvas, Port, Point(NodeRect.Right - 8, PortY));

    gCanvas.Font.Size := 9;
    gCanvas.Font.Color := clSilver;
    TextWidth := gCanvas.TextWidth(Port.Name);
    gCanvas.TextOut(NodeRect.Right - TextWidth - 15, PortY - 8, Port.Name);
  end;
end;


procedure TNodeCanvas.DrawPort(gCanvas: TCanvas; Port: TNodePort; const Position: TPoint);
var
  PortRect: TRect;
  PortColor: TColor;
begin
  PortRect := Rect(Position.X - 8, Position.Y - 8, Position.X + 8, Position.Y + 8);
  Port.Bounds := PortRect;

  if Port.PortType = ptInput then
    PortColor := clSkyBlue
  else
    PortColor := TColor($00A5FF);

  gCanvas.Brush.Color := PortColor;
  gCanvas.Pen.Color := clWhite;
  gCanvas.Pen.Width := 2;
  gCanvas.Ellipse(PortRect);
end;

procedure TNodeCanvas.DrawConnection(gCanvas: TCanvas; Connection: TConnection);
var
  StartPos, EndPos: TPoint;
  IsHighlighted: Boolean;
  ConnectionColor: TColor;
  LineWidth: Integer;
begin
  StartPos := GetPortCenter(Connection.OutputPort);
  EndPos := GetPortCenter(Connection.InputPort);

  IsHighlighted := IsConnectionNearMouse(Connection, FLastMousePos);
  if IsHighlighted then
  begin
    ConnectionColor := clRed;
    LineWidth := 4;
  end
  else
  begin
    ConnectionColor := clYellow;
    LineWidth := 3;
  end;

  DrawBezierConnection(gCanvas, StartPos, EndPos, ConnectionColor, LineWidth);
end;


procedure TNodeCanvas.DrawTempConnection(gCanvas: TCanvas; StartPort: TNodePort; const MousePos: TPoint);
var
  StartPos, EndPos: TPoint;
begin
  StartPos := GetPortCenter(StartPort);
  (*
  EndPos := Point(
    Round((MousePos.X - FCanvasOffset.X) / FZoomLevel),
    Round((MousePos.Y - FCanvasOffset.Y) / FZoomLevel)
  ); *)

  // 수정됨
  EndPos.X := Round((MousePos.X - FCanvasOffset.X) / FZoomLevel);
  EndPos.Y := Round((MousePos.Y - FCanvasOffset.Y) / FZoomLevel);

  DrawBezierConnection(gCanvas, StartPos, EndPos, clGray, 2);
end;

procedure TNodeCanvas.DrawBezierConnection(gCanvas: TCanvas; const StartPos, EndPos: TPoint;
                                         AColor: TColor; LineWidth: Integer);
var
  ControlOffset: Integer;
  Control1, Control2: TPoint;
  Points: array[0..50] of TPoint;
  i: Integer;
  t: Double;
begin
  gCanvas.Pen.Color := AColor;
  gCanvas.Pen.Width := LineWidth;

  ControlOffset := Abs(EndPos.X - StartPos.X) div 2;
  Control1.X := StartPos.X + ControlOffset;
  Control1.Y := StartPos.Y;
  Control2.X := EndPos.X - ControlOffset;
  Control2.Y := EndPos.Y;

  // Simple bezier approximation using line segments
  for i := 0 to 50 do
  begin
    t := i / 50.0;
    Points[i] := CalculateBezierPoint(StartPos, Control1, Control2, EndPos, t);
  end;

  gCanvas.Polyline(Points);
end;



function TNodeCanvas.GetPortCenter(Port: TNodePort): TPoint;
begin
  Result := Point(
    Port.Bounds.Left + (Port.Bounds.Right - Port.Bounds.Left) div 2,
    Port.Bounds.Top + (Port.Bounds.Bottom - Port.Bounds.Top) div 2
  );
end;



function TNodeCanvas.GetNodeAtPosition(const Position: TPoint): TNode;
var
  AdjustedPos: TPoint;
  i, NodeWidth, NodeHeight: Integer;
  NodeRect: TRect;
  Node: TNode;
begin
  Result := nil;

  // 줌과 오프셋을 고려한 좌표 변환
  AdjustedPos.X := Round((Position.X - FCanvasOffset.X) / FZoomLevel);
  AdjustedPos.Y := Round((Position.Y - FCanvasOffset.Y) / FZoomLevel);

  // 위에서부터 아래로 검색 (마지막에 그려진 노드가 맨 위)
  for i := FNodes.Count - 1 downto 0 do
  begin
    Node := FNodes[i];
    if Assigned(Node) then
    begin
      NodeWidth := GetNodeWidth(Node);
      NodeHeight := GetNodeHeight(Node);
      NodeRect := Rect(Node.Position.X, Node.Position.Y,
                       Node.Position.X + NodeWidth, Node.Position.Y + NodeHeight);

      if PtInRect(NodeRect, AdjustedPos) then
      begin
        Result := Node;
        Exit;
      end;
    end;
  end;
end;


function TNodeCanvas.GetPortAtPosition(const Position: TPoint): TNodePort;
var
  AdjustedPos: TPoint;
  i, j: Integer;
  Node: TNode;
  Port: TNodePort;
begin
  Result := nil;

  // 줌과 오프셋을 고려한 좌표 변환
  AdjustedPos.X := Round((Position.X - FCanvasOffset.X) / FZoomLevel);
  AdjustedPos.Y := Round((Position.Y - FCanvasOffset.Y) / FZoomLevel);

  for i := 0 to FNodes.Count - 1 do
  begin
    Node := FNodes[i];
    if not Assigned(Node) then Continue;

    // Input ports 확인
    for j := 0 to Node.InputPorts.Count - 1 do
    begin
      Port := Node.InputPorts[j];
      if Assigned(Port) and PtInRect(Port.Bounds, AdjustedPos) then
      begin
        Result := Port;
        Exit;
      end;
    end;

    // Output ports 확인
    for j := 0 to Node.OutputPorts.Count - 1 do
    begin
      Port := Node.OutputPorts[j];
      if Assigned(Port) and PtInRect(Port.Bounds, AdjustedPos) then
      begin
        Result := Port;
        Exit;
      end;
    end;
  end;
end;




function TNodeCanvas.GetConnectionAtPosition(const Position: TPoint): TConnection;
var
  AdjustedPos: TPoint;
  i: Integer;
  Connection: TConnection;
begin
  Result := nil;

  AdjustedPos := Point(
    Round((Position.X - FCanvasOffset.X) / FZoomLevel),
    Round((Position.Y - FCanvasOffset.Y) / FZoomLevel)
  );

  for i := 0 to FConnections.Count - 1 do
  begin
    Connection := FConnections[i];
    if IsPointOnConnection(Connection, AdjustedPos) then
    begin
      Result := Connection;
      Exit;
    end;
  end;
end;


function TNodeCanvas.IsPointOnConnection(Connection: TConnection; const Point: TPoint): Boolean;
var
  StartPos, EndPos, Control1, Control2, BezierPoint: TPoint;
  ControlOffset, i: Integer;
  t, Distance: Double;
const
  Segments = 20;
  Threshold = 10.0;
begin
  Result := False;

  StartPos := GetPortCenter(Connection.OutputPort);
  EndPos := GetPortCenter(Connection.InputPort);

  ControlOffset := Abs(EndPos.X - StartPos.X) div 2;
  Control1.X := StartPos.X + ControlOffset;
  Control1.Y := StartPos.Y;
  Control2.X := EndPos.X - ControlOffset;
  Control2.Y := EndPos.Y;

  for i := 0 to Segments do
  begin
    t := i / Segments;
    BezierPoint := CalculateBezierPoint(StartPos, Control1, Control2, EndPos, t);

    Distance := Sqrt(Sqr(Point.X - BezierPoint.X) + Sqr(Point.Y - BezierPoint.Y));
    if Distance <= Threshold then
    begin
      Result := True;
      Exit;
    end;
  end;
end;



function TNodeCanvas.IsConnectionNearMouse(Connection: TConnection; const MousePos: TPoint): Boolean;
var
  AdjustedPos: TPoint;
begin
  AdjustedPos := Point(
    Round((MousePos.X - FCanvasOffset.X) / FZoomLevel),
    Round((MousePos.Y - FCanvasOffset.Y) / FZoomLevel)
  );

  Result := IsPointOnConnection(Connection, AdjustedPos);
end;



function TNodeCanvas.CalculateBezierPoint(const P0, P1, P2, P3: TPoint; t: Double): TPoint;
var
  u, tt, uu, uuu, ttt: Double;
  x, y: Double;
begin
  u := 1 - t;
  tt := t * t;
  uu := u * u;
  uuu := uu * u;
  ttt := tt * t;

  x := uuu * P0.X + 3 * uu * t * P1.X + 3 * u * tt * P2.X + ttt * P3.X;
  y := uuu * P0.Y + 3 * uu * t * P1.Y + 3 * u * tt * P2.Y + ttt * P3.Y;

  //Result := Point(Round(x), Round(y));
  // 수정됨
  Result.X := Round(x);
  Result.Y := Round(y);
end;


function TNodeCanvas.CanConnect(Port1, Port2: TNodePort): Boolean;
var
  i: Integer;
  Connection: TConnection;
begin
  Result := (Port1.PortType <> Port2.PortType);

  if Result then
  begin
    for i := 0 to FConnections.Count - 1 do
    begin
      Connection := FConnections[i];
      if ((Connection.OutputPort = Port1) and (Connection.InputPort = Port2)) or
         ((Connection.OutputPort = Port2) and (Connection.InputPort = Port1)) then
      begin
        Result := False;
        Exit;
      end;
    end;
  end;
end;


procedure TNodeCanvas.ProcessImageFlow(OutputPort, InputPort: TNodePort);
var
  FromPort, ToPort: TNodePort;
  FromNode, ToNode: TNode;
begin
  if OutputPort.PortType = ptOutput then
  begin
    FromPort := OutputPort;
    ToPort := InputPort;
  end
  else
  begin
    FromPort := InputPort;
    ToPort := OutputPort;
  end;

  FromNode := FromPort.ParentNode;
  ToNode := ToPort.ParentNode;

  ProcessSpecificNodeConnection(FromNode, ToNode);
  Invalidate;
end;

procedure TNodeCanvas.RemoveConnection(Connection: TConnection);
begin
  if FConnections.IndexOf(Connection) >= 0 then
  begin
    FConnections.Remove(Connection);
    ResetNodeAfterDisconnection(Connection.InputPort.ParentNode);
    UpdateStatusMessage('연결이 제거되었습니다: ' + Connection.OutputPort.ParentNode.Title + '→' + Connection.InputPort.ParentNode.Title);
    Connection.Free;
  end;
end;


procedure TNodeCanvas.ResetNodeAfterDisconnection(Node: TNode);
var
  HasOutputConnection: Boolean;
  i: Integer;
  Connection: TConnection;
begin
  // Clear input images - don't free as they may be shared
  if Assigned(Node.InputImages) then
    Node.InputImages.Clear;
  if Assigned(Node.InputImageNames) then
    Node.InputImageNames.Clear;

  // Check if node has output connections
  HasOutputConnection := False;
  for i := 0 to FConnections.Count - 1 do
  begin
    Connection := FConnections[i];
    if Assigned(Connection) and Assigned(Connection.OutputPort) and
       (Connection.OutputPort.ParentNode = Node) then
    begin
      HasOutputConnection := True;
      Break;
    end;
  end;

  if (not HasOutputConnection) and (Node.NodeType <> ntOriginal) then
  begin
    for i := 0 to Node.OutputImages.Count - 1 do
    begin
      if Assigned(Node.OutputImages[i]) then
        Node.OutputImages[i].Free;
    end;
    Node.OutputImages.Clear;
    Node.OutputImageNames.Clear;
  end;
end;



procedure TNodeCanvas.UpdateStatusMessage(const Message: string);
var
  ParentControl: TWinControl;
  ParentForm: TForm;
  StatusBar: TStatusBar;
  i: Integer;
begin
  // 부모 폼 찾기
  ParentControl := Self.Parent;
  while (ParentControl <> nil) and not (ParentControl is TForm) do
    ParentControl := ParentControl.Parent;

  ParentForm := ParentControl as TForm;
  if Assigned(ParentForm) then
  begin
    // 컨트롤에서 StatusBar 찾기
    StatusBar := nil;
    for i := 0 to ParentForm.ControlCount - 1 do
    begin
      if ParentForm.Controls[i] is TStatusBar then
      begin
        StatusBar := TStatusBar(ParentForm.Controls[i]);
        Break;
      end;
    end;

    // StatusBar가 없으면 Components에서 찾기
    if StatusBar = nil then
    begin
      for i := 0 to ParentForm.ComponentCount - 1 do
      begin
        if ParentForm.Components[i] is TStatusBar then
        begin
          StatusBar := TStatusBar(ParentForm.Components[i]);
          Break;
        end;
      end;
    end;

    // StatusBar에 메시지 설정
    if Assigned(StatusBar) then
    begin
      if StatusBar.Panels.Count > 0 then
        StatusBar.Panels[0].Text := Message
      else
        StatusBar.SimpleText := Message;
    end;
  end;
end;



procedure TNodeCanvas.ClearAllConnections;
var
  i: Integer;
  Node: TNode;
  Connection: TConnection;
begin
  // Free all connections
  for i := 0 to FConnections.Count - 1 do
  begin
    Connection := FConnections[i];
    Connection.Free;
  end;
  FConnections.Clear;

  // Reset all nodes except original
  for i := 0 to FNodes.Count - 1 do
  begin
    Node := FNodes[i];
    if Node.NodeType <> ntOriginal then
    begin
      ResetNodeAfterDisconnection(Node);
    end;
  end;

  Invalidate;
end;



procedure TNodeCanvas.ResetAllNodes;
var
  i: Integer;
  Node: TNode;
  Connection: TConnection;
begin
  // Clear all connections
  for i := 0 to FConnections.Count - 1 do
  begin
    Connection := FConnections[i];
    Connection.Free;
  end;
  FConnections.Clear;

  // Reset all nodes
  for i := 0 to FNodes.Count - 1 do
  begin
    Node := FNodes[i];
    ResetNodeAfterDisconnection(Node);

    if Node.NodeType = ntOriginal then
      Node.LoadImages(['input.png'], False);
  end;

  Invalidate;
end;


procedure TNodeCanvas.ProcessSpecificNodeConnection(FromNode, ToNode: TNode);
var
  SelectedImages: specialize TList<TImage>;
  SelectedNames: TStringList;
  CombinedImages: specialize TList<TImage>;
  CombinedNames: TStringList;
  EmojiImage: TImage;
  EmojiPath, RelativePath: string;
  Step04Outputs: array of string;
  i: Integer;
begin
  case ToNode.NodeType of
    ntStep01:
      if FromNode.NodeType = ntOriginal then
      begin
        ToNode.SetInputImages(FromNode.OutputImages, FromNode.OutputImageNames);
        ToNode.LoadImages(['images/debug_full_mask.png', 'images/background.png', 'images/output_no_bg.png'], False);
      end;

    ntStep02:
      if FromNode.NodeType = ntStep01 then
      begin
        SelectedImages := specialize TList<TImage>.Create;
        SelectedNames := TStringList.Create;
        try
          if FromNode.OutputImages.Count >= 2 then
          begin
            SelectedImages.Add(FromNode.OutputImages[0]);
            SelectedImages.Add(FromNode.OutputImages[1]);
            SelectedNames.Add('images/debug_full_mask.png');
            SelectedNames.Add('images/background.png');
          end;

          ToNode.SetInputImages(SelectedImages, SelectedNames);
          ToNode.LoadImages(['images/lama_output.png'], False);
        finally
          SelectedImages.Free;
          SelectedNames.Free;
        end;
      end;

    ntStep03:
      if FromNode.NodeType = ntOriginal then
      begin
        CombinedImages := specialize TList<TImage>.Create;
        CombinedNames := TStringList.Create;
        try
          // Copy original images
          for i := 0 to FromNode.OutputImages.Count - 1 do
            CombinedImages.Add(FromNode.OutputImages[i]);

          if Assigned(FromNode.OutputImageNames) then
            CombinedNames.AddStrings(FromNode.OutputImageNames);

          // Add emoji image
          EmojiPath := 'images/emoji_rabbit.png';

          try
            if FileExists(EmojiPath) then
            begin
              EmojiImage := TImage.Create(nil);
              EmojiImage.Picture.LoadFromFile(EmojiPath);
            end
            else
            begin
              // 상대 경로로도 시도
              RelativePath := IncludeTrailingPathDelimiter(ExtractFileDir(Application.ExeName)) + EmojiPath;
              if FileExists(RelativePath) then
              begin
                EmojiImage := TImage.Create(nil);
                EmojiImage.Picture.LoadFromFile(RelativePath);
              end
              else
              begin
                // 파일이 없으면 플레이스홀더 생성
                EmojiImage := FromNode.CreatePlaceholderImage('emoji_rabbit.png', clYellow);
              end;
            end;
          except
            // 오류 발생 시 플레이스홀더 생성
            EmojiImage := FromNode.CreatePlaceholderImage('emoji_rabbit.png', clYellow);
          end;

          CombinedImages.Add(EmojiImage);
          CombinedNames.Add('emoji_rabbit.png');

          ToNode.SetInputImages(CombinedImages, CombinedNames);
          ToNode.LoadImages(['images/output.png'], False);
        finally
          CombinedImages.Free;
          CombinedNames.Free;
        end;
      end;

    ntStep04:
      if FromNode.NodeType = ntStep01 then
      begin
        SelectedImages := specialize TList<TImage>.Create;
        SelectedNames := TStringList.Create;
        try
          if FromNode.OutputImages.Count >= 3 then
          begin
            SelectedImages.Add(FromNode.OutputImages[2]);
            SelectedNames.Add('images/output_no_bg.png');
          end;

          ToNode.SetInputImages(SelectedImages, SelectedNames);

          SetLength(Step04Outputs, 9);
          Step04Outputs[0] := 'images/360_view_001_000deg_from_000deg.png';
          Step04Outputs[1] := 'images/360_view_002_045deg_from_060deg.png';
          Step04Outputs[2] := 'images/360_view_003_090deg_from_090deg.png';
          Step04Outputs[3] := 'images/360_view_004_135deg_from_090deg.png';
          Step04Outputs[4] := 'images/360_view_005_180deg_from_180deg.png';
          Step04Outputs[5] := 'images/360_view_006_225deg_from_240deg.png';
          Step04Outputs[6] := 'images/360_view_007_270deg_from_270deg.png';
          Step04Outputs[7] := 'images/360_view_008_315deg_from_000deg.png';
          Step04Outputs[8] := 'images/ultrafast_360.gif';

          ToNode.LoadImages(Step04Outputs, False);
        finally
          SelectedImages.Free;
          SelectedNames.Free;
        end;
      end;

    ntStep05:
      if FromNode.NodeType = ntStep04 then
      begin
        SelectedImages := specialize TList<TImage>.Create;
        SelectedNames := TStringList.Create;
        try
          if FromNode.OutputImages.Count >= 8 then
          begin
            for i := 0 to 7 do
            begin
              SelectedImages.Add(FromNode.OutputImages[i]);
              SelectedNames.Add(FromNode.OutputImageNames[i]);
            end;
          end;

          ToNode.SetInputImages(SelectedImages, SelectedNames);
          ToNode.LoadImages(['images/step05_sc_2025-08-11.gif'], False);
        finally
          SelectedImages.Free;
          SelectedNames.Free;
        end;
      end;
  end;
end;



{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // 2025.08.16
  // 이벤트 핸들러 명시적 연결
  // => 프로그램 종료시 메모리 오류 발생안하려면 아래 이벤트들이
  //    종료전에 실행이 되어야 함.
  Self.OnCloseQuery := @FormCloseQuery;
  Self.OnDestroy := @FormDestroy;

  InitUI;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // 종료 전에 모든 리소스 정리
  CleanupBeforeClose;
  CanClose := True;
end;

procedure TForm1.CleanupBeforeClose;
begin
  if Assigned(FCanvas) then
  begin
    // 모든 연결 제거
    FCanvas.ClearAllConnections;

    // 모든 노드 리셋 (이미지들 정리)
    FCanvas.ResetAllNodes;

    // 추가로 명시적 정리
    FCanvas.UpdateStatusMessage('프로그램을 종료합니다...');
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  // 종료 전에 모든 리소스 정리
  CleanupBeforeClose;

(*
  // FormCloseQuery에서 이미 정리했지만 추가 안전장치
  if Assigned(FCanvas) then
  begin
    FCanvas.Free;
    FCanvas := nil;
  end;
 *)
end;


procedure TForm1.InitUI;
begin
  Caption := '이미지 처리 워크플로우 - Node Based UI from Lazarus';
  Width := 1400;
  Height := 900;
  Position := poScreenCenter;

  // 메뉴 생성
  CreateMenus;

  FCanvas := TNodeCanvas.Create(Self);
  FCanvas.Parent := Self;
  FCanvas.Align := alClient;

  // Create status bar
  CreateStatusBar;

  WindowState := wsMaximized;
end;

// 새로운 메서드 추가
procedure TForm1.CreateMenus;
begin
  if not Assigned(MainMenu1) then
    MainMenu1 := TMainMenu.Create(Self);

  Self.Menu := MainMenu1;

  // File Menu
  FileMenu := TMenuItem.Create(MainMenu1);
  FileMenu.Caption := '파일';
  MainMenu1.Items.Add(FileMenu);

  LoadImageItem := TMenuItem.Create(FileMenu);
  LoadImageItem.Caption := '원본 이미지 로드';
  LoadImageItem.OnClick := @LoadImageItemClick;
  FileMenu.Add(LoadImageItem);

  SaveAllItem := TMenuItem.Create(FileMenu);
  SaveAllItem.Caption := '모든 결과 저장';
  SaveAllItem.OnClick := @SaveAllItemClick;
  FileMenu.Add(SaveAllItem);

  FileMenu.Add(TMenuItem.Create(FileMenu)); // Separator
  FileMenu.Items[FileMenu.Count-1].Caption := '-';

  ExitItem := TMenuItem.Create(FileMenu);
  ExitItem.Caption := '종료';
  ExitItem.OnClick := @ExitItemClick;
  FileMenu.Add(ExitItem);

  // Edit Menu
  EditMenu := TMenuItem.Create(MainMenu1);
  EditMenu.Caption := '편집';
  MainMenu1.Items.Add(EditMenu);

  ClearAllConnectionsItem := TMenuItem.Create(EditMenu);
  ClearAllConnectionsItem.Caption := '모든 연결 제거';
  ClearAllConnectionsItem.OnClick := @ClearAllConnectionsItemClick;
  EditMenu.Add(ClearAllConnectionsItem);

  ResetAllNodesItem := TMenuItem.Create(EditMenu);
  ResetAllNodesItem.Caption := '모든 노드 리셋';
  ResetAllNodesItem.OnClick := @ResetAllNodesItemClick;
  EditMenu.Add(ResetAllNodesItem);

  // View Menu
  ViewMenu := TMenuItem.Create(MainMenu1);
  ViewMenu.Caption := '보기';
  MainMenu1.Items.Add(ViewMenu);

  ResetViewItem := TMenuItem.Create(ViewMenu);
  ResetViewItem.Caption := '뷰 리셋';
  ResetViewItem.OnClick := @ResetViewItemClick;
  ViewMenu.Add(ResetViewItem);

  FitToScreenItem := TMenuItem.Create(ViewMenu);
  FitToScreenItem.Caption := '화면에 맞춤';
  FitToScreenItem.OnClick := @FitToScreenItemClick;
  ViewMenu.Add(FitToScreenItem);

  // Help Menu
  HelpMenu := TMenuItem.Create(MainMenu1);
  HelpMenu.Caption := '도움말';
  MainMenu1.Items.Add(HelpMenu);

  AboutItem := TMenuItem.Create(HelpMenu);
  AboutItem.Caption := '정보';
  AboutItem.OnClick := @AboutItemClick;
  HelpMenu.Add(AboutItem);
end;

procedure TForm1.CreateStatusBar;
begin
  if not Assigned(StatusBar1) then
    StatusBar1 := TStatusBar.Create(Self);

  StatusBar1.Parent := Self;
  StatusBar1.Align := alBottom;

  StatusBar1.Panels.Clear;
  StatusBar1.Panels.Add;
  StatusBar1.Panels[0].Text := '준비됨 - 노드를 연결하여 이미지 처리 워크플로우를 시작하세요';
  StatusBar1.Panels[0].Width := 500;
  StatusBar1.Panels.Add;
  StatusBar1.Panels[1].Text := '노드: 6개';
  StatusBar1.Visible := True;
end;


procedure TForm1.LoadImageItemClick(Sender: TObject);
var
  Dialog: TOpenDialog;
  OriginalNode: TNode;
  LoadedImage: TImage;
  i: Integer;
begin
  Dialog := TOpenDialog.Create(Self);
  try
    Dialog.Filter := '이미지 파일|*.jpg;*.jpeg;*.png;*.bmp;*.gif|모든 파일|*.*';
    Dialog.Title := '원본 이미지 선택';

    if Dialog.Execute then
    begin
      try
        OriginalNode := nil;
        for i := 0 to FCanvas.Nodes.Count - 1 do
        begin
          if FCanvas.Nodes[i].NodeType = ntOriginal then
          begin
            OriginalNode := FCanvas.Nodes[i];
            Break;
          end;
        end;

        if Assigned(OriginalNode) then
        begin
          // Clear existing images
          for i := 0 to OriginalNode.OutputImages.Count - 1 do
          begin
            if Assigned(OriginalNode.OutputImages[i]) then
              OriginalNode.OutputImages[i].Free;
          end;
          OriginalNode.OutputImages.Clear;
          OriginalNode.OutputImageNames.Clear;

          // Load new image
          LoadedImage := TImage.Create(nil);
          try
            LoadedImage.Picture.LoadFromFile(Dialog.FileName);
            OriginalNode.OutputImages.Add(LoadedImage);
            OriginalNode.OutputImageNames.Add(ExtractFileName(Dialog.FileName));

            FCanvas.Invalidate;

            MessageDlg('로드 완료', '이미지가 로드되었습니다: ' + ExtractFileName(Dialog.FileName),
                      mtInformation, [mbOK], 0);
          except
            LoadedImage.Free;
            raise;
          end;
        end;
      except
        on E: Exception do
        begin
          MessageDlg('오류', '이미지 로드 중 오류가 발생했습니다:'#13#10 + E.Message,
                    mtError, [mbOK], 0);
        end;
      end;
    end;
  finally
    Dialog.Free;
  end;
end;



procedure TForm1.SaveAllItemClick(Sender: TObject);
begin
  ShowMessage('저장 기능은 구현 예정입니다.');
end;


procedure TForm1.ClearAllConnectionsItemClick(Sender: TObject);
begin
  if MessageDlg('모든 연결을 제거하시겠습니까?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    FCanvas.ClearAllConnections;
end;


procedure TForm1.ResetAllNodesItemClick(Sender: TObject);
begin
  if MessageDlg('모든 노드를 리셋하시겠습니까?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    FCanvas.ResetAllNodes;
end;


procedure TForm1.ResetViewItemClick(Sender: TObject);
begin
  FCanvas.Invalidate;
end;


procedure TForm1.FitToScreenItemClick(Sender: TObject);
begin
  FCanvas.Invalidate;
end;

procedure TForm1.AboutItemClick(Sender: TObject);
begin
  ShowMessage(
    '이미지 처리 워크플로우 시스템'#13#10#13#10 +
    '사용법:'#13#10 +
    '1. 노드를 드래그하여 이동'#13#10 +
    '2. 출력 포트에서 입력 포트로 연결'#13#10 +
    '3. 연결선을 우클릭하여 제거'#13#10 +
    '4. 마우스 휠로 확대/축소'#13#10 +
    '5. 가운데 버튼으로 캔버스 이동'#13#10#13#10 +
    '각 단계별로 이미지가 자동 처리됩니다.'
  );
end;


procedure TForm1.ExitItemClick(Sender: TObject);
begin
  // 종료 전 정리 후 닫기
  CleanupBeforeClose;
  Close;
end;

end.
