unit Unit1;

{$reference 'System.Windows.Forms.dll'}
{$reference 'System.Drawing.dll'}

interface

uses System,
     System.Collections.Generic,
     System.Drawing,
     System.Drawing.Drawing2D,
     System.Drawing.Imaging,
     System.Linq,
     System.Windows.Forms,
     System.IO;

type
  TNodeType = (Original, Step01, Step02, Step03, Step04, Step05);
  TPortType = (Input, Output);
  
  // Forward declarations
  Node = class;
  NodePort = class;
  Connection = class;
  NodeCanvas = class;
  
  NodePort = class
  private
    FName: string;
    FType: TPortType;
    FParentNode: Node;
    FBounds: Rectangle;
  public
    constructor Create(name: string; portType: TPortType; parentNode: Node);
    
    property Name: string read FName write FName;
    property PortType: TPortType read FType write FType;
    property ParentNode: Node read FParentNode write FParentNode;
    property Bounds: Rectangle read FBounds write FBounds;
  end;
  
  Node = class
  private
    FTitle: string;
    FPosition: Point;
    FInputPorts: List<NodePort>;
    FOutputPorts: List<NodePort>;
    FInputImages: List<Image>;
    FOutputImages: List<Image>;
    FInputImageNames: List<string>;
    FOutputImageNames: List<string>;
    FType: TNodeType;
  public
    constructor Create(title: string; position: Point; nodeType: TNodeType);
    procedure Dispose; //destructor Destroy; override;
    
    procedure LoadImages(imageFileNames: array of string; isInput: boolean := true);
    procedure SetInputImages(images: List<Image>; imageNames: List<string>);
    function CreatePlaceholderImage(fileName: string; backgroundColor: Color): Image;
    function GetPlaceholderColor(fileName: string): Color;
    
    property Title: string read FTitle write FTitle;
    property Position: Point read FPosition write FPosition;
    property InputPorts: List<NodePort> read FInputPorts;
    property OutputPorts: List<NodePort> read FOutputPorts;
    property InputImages: List<Image> read FInputImages;
    property OutputImages: List<Image> read FOutputImages;
    property InputImageNames: List<string> read FInputImageNames;
    property OutputImageNames: List<string> read FOutputImageNames;
    property NodeType: TNodeType read FType write FType;
  end;

  Connection = class
  private
    FOutputPort: NodePort;
    FInputPort: NodePort;
  public
    constructor Create(outputPort, inputPort: NodePort);
    
    property OutputPort: NodePort read FOutputPort write FOutputPort;
    property InputPort: NodePort read FInputPort write FInputPort;
  end;

  NodeCanvas = class(UserControl)
  private
    nodes: List<Node>;
    connections: List<Connection>;
    draggedNode: Node;
    connectionStartPort: NodePort;
    lastMousePos: Point;
    canvasOffset: Point;
    isPanning: boolean;
    zoomLevel: real;
    animationTimer: Timer;
    animatedImages: Dictionary<Image, boolean>;
    
    procedure InitializeComponent;
    procedure AddProcessingNodes;
    
    // Event handlers
    procedure NodeCanvas_MouseDown(sender: Object; e: MouseEventArgs);
    procedure NodeCanvas_MouseMove(sender: Object; e: MouseEventArgs);
    procedure NodeCanvas_MouseUp(sender: Object; e: MouseEventArgs);
    procedure NodeCanvas_Paint(sender: Object; e: PaintEventArgs);
    procedure NodeCanvas_MouseWheel(sender: Object; e: MouseEventArgs);
    procedure AnimationTimer_Tick(sender: Object; e: EventArgs);
    
    // Drawing methods
    procedure DrawGrid(g: Graphics);
    procedure DrawNode(g: Graphics; node: Node);
    procedure DrawNodeImages(g: Graphics; node: Node; nodeRect: Rectangle);
    procedure DrawNodePorts(g: Graphics; node: Node; nodeRect: Rectangle);
    procedure DrawPort(g: Graphics; port: NodePort; position: Point);
    procedure DrawConnection(g: Graphics; connection: Connection);
    procedure DrawTempConnection(g: Graphics; startPort: NodePort; mousePos: Point);
    procedure DrawBezierConnection(g: Graphics; startPos, endPos: Point; color: Color; lineWidth: integer := 3);
    
    // Utility methods
    function GetNodeWidth(node: Node): integer;
    function GetNodeHeight(node: Node): integer;
    function GetNodeColor(nodeType: TNodeType): Color;
    function GetPortCenter(port: NodePort): Point;
    function GetNodeAtPosition(position: Point): Node;
    function GetPortAtPosition(position: Point): NodePort;
    function GetConnectionAtPosition(position: Point): Connection;
    function IsPointOnConnection(connection: Connection; point: Point): boolean;
    function IsConnectionNearMouse(connection: Connection; mousePos: Point): boolean;
    function CalculateBezierPoint(p0, p1, p2, p3: Point; t: real): Point;
    function CanConnect(port1, port2: NodePort): boolean;
    function IsAnimatedGif(image: Image): boolean;
    
    // Processing methods
    procedure ProcessImageFlow(outputPort, inputPort: NodePort);
    procedure ProcessSpecificNodeConnection(fromNode, toNode: Node);
    procedure RemoveConnection(connection: Connection);
    procedure ResetNodeAfterDisconnection(node: Node);
    procedure UpdateStatusMessage(message: string);
    procedure OnFrameChanged(sender: Object; e: EventArgs);
    
  public
    constructor Create;
    procedure Dispose;//destructor Destroy; override;
    
    procedure ClearAllConnections;
    procedure ResetAllNodes;
    procedure CleanupAnimations;
    
    property TNodes: List<Node> read nodes;
    property TConnections: List<Connection> read connections;
  end;
  
  Form1 = class(Form)
  {$region FormDesigner}
  internal
    {$include Unit1.Form1.inc}
  {$endregion FormDesigner}
  private 
    canvas: NodeCanvas;
    menuStrip: MenuStrip;
    
    procedure CreateMenuStrip;
    procedure CreateStatusBar;
    procedure LoadImageItem_Click(sender: Object; e: EventArgs);
    procedure SaveAllItem_Click(sender: Object; e: EventArgs);
    procedure ClearAllConnectionsItem_Click(sender: Object; e: EventArgs);
    procedure ResetAllNodesItem_Click(sender: Object; e: EventArgs);
    procedure ResetViewItem_Click(sender: Object; e: EventArgs);
    procedure FitToScreenItem_Click(sender: Object; e: EventArgs);
    procedure AboutItem_Click(sender: Object; e: EventArgs);
    procedure ExitItem_Click(sender: Object; e: EventArgs);
    procedure InitUI;    
  public
    constructor Create;
  end;

// Helper extension methods simulation
procedure FillRoundedRectangle(g: Graphics; brush: Brush; rect: Rectangle; radius: integer);
procedure DrawRoundedRectangle(g: Graphics; pen: Pen; rect: Rectangle; radius: integer);
function CreateRoundedRectanglePath(rect: Rectangle; radius: integer): GraphicsPath;

implementation

// NodePort implementation
constructor NodePort.Create(name: string; portType: TPortType; parentNode: Node);
begin
  FName := name;
  FType := portType;
  FParentNode := parentNode;
end;

// Node implementation
constructor Node.Create(title: string; position: Point; nodeType: TNodeType);
begin
  FTitle := title;
  FPosition := position;
  FType := nodeType;
  FInputPorts := new List<NodePort>;
  FOutputPorts := new List<NodePort>;
  FInputImages := new List<Image>;
  FOutputImages := new List<Image>;
  FInputImageNames := new List<string>;
  FOutputImageNames := new List<string>;
end;

(*
destructor Node.Destroy;
var
  img: Image;
begin
  // Input 이미지들 정리
  for var i := 0 to FInputImages.Count - 1 do
  begin
    img := FInputImages[i];
    if img <> nil then
      img.Dispose();
  end;
  FInputImages.Clear();
  
  // Output 이미지들 정리
  for var i := 0 to FOutputImages.Count - 1 do
  begin
    img := FOutputImages[i];
    if img <> nil then
      img.Dispose();
  end;
  FOutputImages.Clear();
  
  inherited;
end;
*)
// destructor 대신 Dispose 메서드 사용
procedure Node.Dispose;
var
  img: Image;
begin
  // Input 이미지들 정리
  for var i := 0 to FInputImages.Count - 1 do
  begin
    img := FInputImages[i];
    if img <> nil then
      img.Dispose();
  end;
  FInputImages.Clear();
  
  // Output 이미지들 정리
  for var i := 0 to FOutputImages.Count - 1 do
  begin
    img := FOutputImages[i];
    if img <> nil then
      img.Dispose();
  end;
  FOutputImages.Clear();
end;

procedure Node.LoadImages(imageFileNames: array of string; isInput: boolean); //isInput: boolean := true
var
  images: List<Image>;
  imageNames: List<string>;
  fileName: string;
  image: Image;
  imageBytes: array of byte;
  originalStream, imageStream: MemoryStream;
  placeholderColor: Color;
begin
  if isInput then
  begin
    images := FInputImages;
    imageNames := FInputImageNames;
  end
  else
  begin
    images := FOutputImages;
    imageNames := FOutputImageNames;
  end;
  
  // 기존 이미지들 정리
  for var i := 0 to images.Count - 1 do
  begin
    image := images[i];
    if image <> nil then
      image.Dispose();
  end;
  
  images.Clear();
  imageNames.Clear();
  
  for var i := 0 to Length(imageFileNames) - 1 do
  begin
    fileName := imageFileNames[i];
    try
      if System.IO.File.Exists(fileName) then
      begin
        // 모든 이미지 파일을 바이트 배열로 읽어서 처리
        imageBytes := System.IO.File.ReadAllBytes(fileName);
        originalStream := new MemoryStream(imageBytes);
        try
          // 새로운 MemoryStream을 생성하여 Image 객체가 독립적으로 사용할 수 있도록 함
          imageStream := new MemoryStream(imageBytes);
          image := System.Drawing.Image.FromStream(imageStream);
        finally
          originalStream.Dispose();
        end;
      end
      else
      begin
        placeholderColor := GetPlaceholderColor(fileName);
        image := CreatePlaceholderImage(fileName, placeholderColor);
      end;
      
      images.Add(image);
      imageNames.Add(fileName);
    except
      on ex: Exception do
      begin
        // 상세한 예외 정보 출력
        System.Diagnostics.Debug.WriteLine('이미지 로드 실패:');
        System.Diagnostics.Debug.WriteLine('  파일명: ' + fileName);
        System.Diagnostics.Debug.WriteLine('  오류: ' + ex.Message);
        System.Diagnostics.Debug.WriteLine('  스택 트레이스: ' + ex.StackTrace);
        
        image := CreatePlaceholderImage('ERROR: ' + Path.GetFileName(fileName), Color.Red);
        images.Add(image);
        imageNames.Add(fileName);
      end;
    end;
  end;
end;

procedure Node.SetInputImages(images: List<Image>; imageNames: List<string>);
begin
  FInputImages.Clear();
  FInputImageNames.Clear();
  
  if images <> nil then
    FInputImages.AddRange(images);
  
  if imageNames <> nil then
    FInputImageNames.AddRange(imageNames);
end;

function Node.GetPlaceholderColor(fileName: string): Color;
var
  lowerFileName: string;
begin
  lowerFileName := fileName.ToLower();
  
  if lowerFileName.Contains('input') then
    Result := Color.LightBlue
  else if lowerFileName.Contains('mask') then
    Result := Color.Purple
  else if lowerFileName.Contains('background') then
    Result := Color.Green
  else if lowerFileName.Contains('output') then
    Result := Color.Orange
  else if lowerFileName.Contains('lama') then
    Result := Color.Cyan
  else if lowerFileName.Contains('emoji') then
    Result := Color.Yellow
  else if lowerFileName.Contains('360') then
    Result := Color.Pink
  else if lowerFileName.Contains('gif') then
    Result := Color.Magenta
  else if lowerFileName.Contains('step05') then
    Result := Color.LimeGreen
  else
    Result := Color.Gray;
end;

function Node.CreatePlaceholderImage(fileName: string; backgroundColor: Color): Image;
var
  image: Bitmap;
  g: Graphics;
  font: System.Drawing.Font;
  displayName: string;
  textSize: SizeF;
  x, y: real;
begin
  image := new Bitmap(100, 80);
  g := Graphics.FromImage(image);
  try
    g.FillRectangle(new SolidBrush(backgroundColor), 0, 0, 100, 80);
    
    font := new System.Drawing.Font('Arial', 7, FontStyle.Bold);
    try
      displayName := Path.GetFileNameWithoutExtension(fileName);
      if displayName.Length > 15 then
        displayName := displayName.Substring(0, 15) + '...';
      
      textSize := g.MeasureString(displayName, font);
      x := Max(2, (100 - textSize.Width) / 2);
      y := Max(2, (80 - textSize.Height) / 2);
      
      g.DrawString(displayName, font, Brushes.Black, x, y);
    finally
      font.Dispose();
    end;
    
    g.DrawRectangle(Pens.Black, 0, 0, 99, 79);
  finally
    g.Dispose();
  end;
  
  Result := image;
end;

// Connection implementation
constructor Connection.Create(outputPort, inputPort: NodePort);
begin
  if (outputPort.PortType = TPortType.Output) and (inputPort.PortType = TPortType.Input) then
  begin
    FOutputPort := outputPort;
    FInputPort := inputPort;
  end
  else
  begin
    if inputPort.PortType = TPortType.Output then
      FOutputPort := inputPort
    else
      FOutputPort := outputPort;
    
    if inputPort.PortType = TPortType.Input then
      FInputPort := inputPort
    else
      FInputPort := outputPort;
  end;
end;

// Part 2: NodeCanvas 구현부 - Part 1 다음에 이어서 작성하세요

// NodeCanvas implementation
constructor NodeCanvas.Create;
begin
  inherited Create;
  
  nodes := new List<Node>;
  connections := new List<Connection>;
  draggedNode := nil;
  connectionStartPort := nil;
  canvasOffset := Point.Empty;
  isPanning := false;
  zoomLevel := 1.0;
  animatedImages := new Dictionary<Image, boolean>;
  
  InitializeComponent();
  
  // Event handlers
  Self.MouseDown += NodeCanvas_MouseDown;
  Self.MouseMove += NodeCanvas_MouseMove;
  Self.MouseUp += NodeCanvas_MouseUp;
  Self.Paint += NodeCanvas_Paint;
  Self.MouseWheel += NodeCanvas_MouseWheel;
  
  // GIF 애니메이션을 위한 타이머 설정
  animationTimer := new Timer();
  animationTimer.Interval := 50; // 50ms 간격으로 업데이트
  animationTimer.Tick += AnimationTimer_Tick;
  animationTimer.Start();
  
  AddProcessingNodes();
end;

(*
destructor NodeCanvas.Destroy;
begin
  CleanupAnimations();
  if animationTimer <> nil then
    animationTimer.Dispose();
  inherited;
end;
*)
// destructor 대신 Dispose 메서드 사용
procedure NodeCanvas.Dispose;
var
  node: Node;
begin
  CleanupAnimations();
  
  // 모든 노드들 정리
  for var i := 0 to nodes.Count - 1 do
  begin
    node := nodes[i];
    if node <> nil then
      node.Dispose();
  end;
  
  if animationTimer <> nil then
    animationTimer.Dispose();
    
  // 부모 클래스의 Dispose 호출
  inherited Dispose();
end;

procedure NodeCanvas.InitializeComponent;
begin
  SetStyle(ControlStyles.AllPaintingInWmPaint or 
          ControlStyles.UserPaint or 
          ControlStyles.DoubleBuffer or 
          ControlStyles.ResizeRedraw, true);
  
  Self.BackColor := Color.FromArgb(45, 45, 48);
  Self.Size := new System.Drawing.Size(1200, 800);
end;

procedure NodeCanvas.AddProcessingNodes;
var
  originalNode, step01Node, step02Node, step03Node, step04Node, step05Node: Node;
begin
  // 원본 이미지 노드
  originalNode := new Node('원본이미지', new Point(50, 30), TNodeType.Original);
  originalNode.OutputPorts.Add(new NodePort('Output', TPortType.Output, originalNode));
  originalNode.LoadImages(['images/input.png'], false);
  nodes.Add(originalNode);
  
  // Step01 노드
  step01Node := new Node('Step01', new Point(300, 30), TNodeType.Step01);
  step01Node.InputPorts.Add(new NodePort('Input', TPortType.Input, step01Node));
  step01Node.OutputPorts.Add(new NodePort('Output', TPortType.Output, step01Node));
  nodes.Add(step01Node);
  
  // Step02 노드
  step02Node := new Node('Step02', new Point(600, 30), TNodeType.Step02);
  step02Node.InputPorts.Add(new NodePort('Input', TPortType.Input, step02Node));
  step02Node.OutputPorts.Add(new NodePort('Output', TPortType.Output, step02Node));
  nodes.Add(step02Node);
  
  // Step03 노드
  step03Node := new Node('Step03', new Point(300, 330), TNodeType.Step03);
  step03Node.InputPorts.Add(new NodePort('Input', TPortType.Input, step03Node));
  step03Node.OutputPorts.Add(new NodePort('Output', TPortType.Output, step03Node));
  nodes.Add(step03Node);
  
  // Step04 노드
  step04Node := new Node('Step04', new Point(600, 330), TNodeType.Step04);
  step04Node.InputPorts.Add(new NodePort('Input', TPortType.Input, step04Node));
  step04Node.OutputPorts.Add(new NodePort('Output', TPortType.Output, step04Node));
  nodes.Add(step04Node);
  
  // Step05 노드
  step05Node := new Node('Step05', new Point(900, 330), TNodeType.Step05);
  step05Node.InputPorts.Add(new NodePort('Input', TPortType.Input, step05Node));
  step05Node.OutputPorts.Add(new NodePort('Output', TPortType.Output, step05Node));
  nodes.Add(step05Node);
end;

procedure NodeCanvas.AnimationTimer_Tick(sender: Object; e: EventArgs);
var
  hasAnimatedImages: boolean;
  node: Node;
  image: Image;
begin
  hasAnimatedImages := false;
  
  // 모든 노드의 이미지들을 확인하여 GIF 애니메이션 업데이트
  for var i := 0 to nodes.Count - 1 do
  begin
    node := nodes[i];
    if node.InputImages <> nil then
    begin
      for var j := 0 to node.InputImages.Count - 1 do
      begin
        image := node.InputImages[j];
        if (image <> nil) and IsAnimatedGif(image) then
        begin
          // 애니메이션 등록이 안 되어 있으면 등록
          if not animatedImages.ContainsKey(image) then
          begin
            ImageAnimator.Animate(image, OnFrameChanged);
            animatedImages[image] := true;
          end;
          
          ImageAnimator.UpdateFrames(image);
          hasAnimatedImages := true;
        end;
      end;
    end;
    
    if node.OutputImages <> nil then
    begin
      for var j := 0 to node.OutputImages.Count - 1 do
      begin
        image := node.OutputImages[j];
        if (image <> nil) and IsAnimatedGif(image) then
        begin
          // 애니메이션 등록이 안 되어 있으면 등록
          if not animatedImages.ContainsKey(image) then
          begin
            ImageAnimator.Animate(image, OnFrameChanged);
            animatedImages[image] := true;
          end;
          
          ImageAnimator.UpdateFrames(image);
          hasAnimatedImages := true;
        end;
      end;
    end;
  end;
  
  // 애니메이션이 있는 경우에만 다시 그리기
  if hasAnimatedImages then
    Self.Invalidate();
end;

procedure NodeCanvas.OnFrameChanged(sender: Object; e: EventArgs);
begin
  // UI 스레드에서 안전하게 호출되도록 보장
  if Self.InvokeRequired then
    Self.BeginInvoke(procedure -> Self.Invalidate())
  else
    Self.Invalidate();
end;

function NodeCanvas.IsAnimatedGif(image: Image): boolean;
var
  dimension: FrameDimension;
  frameCount: integer;
begin
  Result := false;
  
  if image = nil then
    exit;
  
  try
    // GIF 형식이고 프레임이 2개 이상인지 확인
    if image.RawFormat.Equals(ImageFormat.Gif) then
    begin
      dimension := new FrameDimension(image.FrameDimensionsList[0]);
      frameCount := image.GetFrameCount(dimension);
      Result := frameCount > 1;
    end;
  except
    // 예외 발생 시 애니메이션 GIF가 아닌 것으로 처리
    Result := false;
  end;
end;

procedure NodeCanvas.CleanupAnimations;
var
  image: Image;
  keys: array of System.Drawing.Image;
begin
  // 등록된 애니메이션 정리
  keys := animatedImages.Keys.ToArray();
  for var i := 0 to Length(keys) - 1 do
  begin
    image := keys[i];
    try
      ImageAnimator.StopAnimate(image, OnFrameChanged);
    except
      // 정리 중 예외는 무시
    end;
  end;
  animatedImages.Clear();
end;

procedure NodeCanvas.NodeCanvas_MouseDown(sender: Object; e: MouseEventArgs);
var
  clickedConnection: Connection;
  clickedPort: NodePort;
begin
  lastMousePos := e.Location;
  
  if e.Button = System.Windows.Forms.MouseButtons.Middle then
  begin
    isPanning := true;
    exit;
  end;
  
  // 우클릭 시 연결선 제거 확인
  if e.Button = System.Windows.Forms.MouseButtons.Right then
  begin
    clickedConnection := GetConnectionAtPosition(e.Location);
    if clickedConnection <> nil then
    begin
      RemoveConnection(clickedConnection);
      Self.Invalidate();
      exit;
    end;
    
    // 연결 생성 취소
    if connectionStartPort <> nil then
    begin
      connectionStartPort := nil;
      Self.Invalidate();
      exit;
    end;
  end;
  
  // 포트 클릭 확인
  clickedPort := GetPortAtPosition(e.Location);
  if (clickedPort <> nil) and (e.Button = System.Windows.Forms.MouseButtons.Left) then
  begin
    if connectionStartPort = nil then
    begin
      connectionStartPort := clickedPort;
    end
    else
    begin
      // 연결 생성
      if CanConnect(connectionStartPort, clickedPort) then
      begin
        connections.Add(new Connection(connectionStartPort, clickedPort));
        ProcessImageFlow(connectionStartPort, clickedPort);
      end;
      connectionStartPort := nil;
    end;
    Self.Invalidate();
    exit;
  end;
  
  // 노드 클릭 확인
  if e.Button = System.Windows.Forms.MouseButtons.Left then
  begin
    draggedNode := GetNodeAtPosition(e.Location);
    if draggedNode <> nil then
    begin
      nodes.Remove(draggedNode);
      nodes.Add(draggedNode);
    end;
  end;
end;

procedure NodeCanvas.NodeCanvas_MouseMove(sender: Object; e: MouseEventArgs);
begin
  if isPanning then
  begin
    canvasOffset.X := canvasOffset.X + e.X - lastMousePos.X;
    canvasOffset.Y := canvasOffset.Y + e.Y - lastMousePos.Y;
    Self.Invalidate();
  end
  else if draggedNode <> nil then
  begin
    draggedNode.Position := new Point(
      draggedNode.Position.X + e.X - lastMousePos.X,
      draggedNode.Position.Y + e.Y - lastMousePos.Y
    );
    Self.Invalidate();
  end
  else if connectionStartPort <> nil then
  begin
    Self.Invalidate();
  end;
  
  lastMousePos := e.Location;
end;

procedure NodeCanvas.NodeCanvas_MouseUp(sender: Object; e: MouseEventArgs);
begin
  draggedNode := nil;
  isPanning := false;
end;

procedure NodeCanvas.NodeCanvas_MouseWheel(sender: Object; e: MouseEventArgs);
var
  oldZoom: real;
begin
  oldZoom := zoomLevel;
  if e.Delta > 0 then
    zoomLevel := zoomLevel + 0.1
  else
    zoomLevel := zoomLevel - 0.1;
  
  zoomLevel := Max(0.1, Min(3.0, zoomLevel));
  
  if oldZoom <> zoomLevel then
    Self.Invalidate();
end;

procedure NodeCanvas.NodeCanvas_Paint(sender: Object; e: PaintEventArgs);
var
  g: Graphics;
  connection: Connection;
  node: Node;
begin
  g := e.Graphics;
  g.SmoothingMode := SmoothingMode.AntiAlias;
  
  g.TranslateTransform(canvasOffset.X, canvasOffset.Y);
  g.ScaleTransform(zoomLevel, zoomLevel);
  
  DrawGrid(g);
  
  for var i := 0 to connections.Count - 1 do
  begin
    connection := connections[i];
    DrawConnection(g, connection);
  end;
  
  if connectionStartPort <> nil then
    DrawTempConnection(g, connectionStartPort, lastMousePos);
  
  for var i := 0 to nodes.Count - 1 do
  begin
    node := nodes[i];
    DrawNode(g, node);
  end;
end;

procedure NodeCanvas.DrawGrid(g: Graphics);
var
  gridPen: Pen;
  gridSize, startX, startY, x, y: integer;
begin
  gridPen := new Pen(Color.FromArgb(60, 60, 63), 1);
  try
    gridSize := 20;
    startX := -(canvasOffset.X mod gridSize);
    startY := -(canvasOffset.Y mod gridSize);
    
    x := startX;
    while x < Self.Width do
    begin
      g.DrawLine(gridPen, x, 0, x, Self.Height);
      x := x + gridSize;
    end;
    
    y := startY;
    while y < Self.Height do
    begin
      g.DrawLine(gridPen, 0, y, Self.Width, y);
      y := y + gridSize;
    end;
  finally
    gridPen.Dispose();
  end;
end;

function NodeCanvas.GetNodeWidth(node: Node): integer;
var
  maxImages, imagesPerRow, baseWidth: integer;
  hasGif: boolean;
  image: Image;
begin
  maxImages := Max(node.InputImages.Count, node.OutputImages.Count);
  imagesPerRow := Min(4, maxImages);
  baseWidth := Max(200, 20 + imagesPerRow * 65);
  
  // Step04나 Step05에서 GIF가 있는 경우 최소 너비 보장
  if ((node.NodeType = TNodeType.Step04) or (node.NodeType = TNodeType.Step05)) and (node.OutputImages <> nil) then
  begin
    hasGif := false;
    for var i := 0 to node.OutputImages.Count - 1 do
    begin
      image := node.OutputImages[i];
      if (image <> nil) and IsAnimatedGif(image) then
      begin
        hasGif := true;
        break;
      end;
    end;
    
    if hasGif then
      // 3배 크기 GIF (180px) + 여백을 수용할 수 있는 최소 너비
      baseWidth := Max(baseWidth, 200);
  end;
  
  Result := baseWidth;
end;

function NodeCanvas.GetNodeHeight(node: Node): integer;
var
  inputRows, outputRows, baseHeight, imageHeight: integer;
  hasGif: boolean;
  image: Image;
begin
  if node.InputImages <> nil then
    inputRows := (node.InputImages.Count - 1) div 4 + 1
  else
    inputRows := 0;
    
  if node.OutputImages <> nil then
    outputRows := (node.OutputImages.Count - 1) div 4 + 1
  else
    outputRows := 0;
  
  baseHeight := 80;
  imageHeight := (inputRows + outputRows) * 80;
  
  if inputRows > 0 then imageHeight := imageHeight + 20;
  if outputRows > 0 then imageHeight := imageHeight + 20;
  
// Part 3: 나머지 구현부 - Part 2 다음에 이어서 작성하세요

  // Step04나 Step05에서 GIF가 있는 경우 추가 높이 계산
  if ((node.NodeType = TNodeType.Step04) or (node.NodeType = TNodeType.Step05)) and (node.OutputImages <> nil) then
  begin
    hasGif := false;
    for var i := 0 to node.OutputImages.Count - 1 do
    begin
      image := node.OutputImages[i];
      if (image <> nil) and IsAnimatedGif(image) then
      begin
        hasGif := true;
        break;
      end;
    end;
    
    if hasGif then
      // 3배 크기 GIF (180px) + 여백 + 텍스트 공간
      imageHeight := imageHeight + 180 + 30;
  end;
  
  Result := Max(baseHeight, baseHeight + imageHeight);
end;

function NodeCanvas.GetNodeColor(nodeType: TNodeType): Color;
begin
  case nodeType of
    TNodeType.Original: Result := Color.FromArgb(70, 130, 180);
    TNodeType.Step01: Result := Color.FromArgb(220, 20, 60);
    TNodeType.Step02: Result := Color.FromArgb(255, 140, 0);
    TNodeType.Step03: Result := Color.FromArgb(50, 205, 50);
    TNodeType.Step04: Result := Color.FromArgb(138, 43, 226);
    TNodeType.Step05: Result := Color.FromArgb(255, 20, 147);
    else Result := Color.FromArgb(70, 70, 74);
  end;
end;

procedure NodeCanvas.DrawNode(g: Graphics; node: Node);
var
  nodeWidth, nodeHeight: integer;
  nodeRect: Rectangle;
  nodeColor, darkerColor: Color;
  brush: LinearGradientBrush;
  borderPen: Pen;
  font: System.Drawing.Font;
  textBrush: SolidBrush;
  format: StringFormat;
  titleRect: Rectangle;
begin
  nodeWidth := GetNodeWidth(node);
  nodeHeight := GetNodeHeight(node);
  nodeRect := new Rectangle(node.Position.X, node.Position.Y, nodeWidth, nodeHeight);
  
  nodeColor := GetNodeColor(node.NodeType);
  
  // 안전한 색상 계산
  darkerColor := Color.FromArgb(
    Max(0, nodeColor.R - 20),
    Max(0, nodeColor.G - 20), 
    Max(0, nodeColor.B - 20)
  );
  
  brush := new LinearGradientBrush(nodeRect, nodeColor, darkerColor, 90.0);
  try
    FillRoundedRectangle(g, brush, nodeRect, 8);
  finally
    brush.Dispose();
  end;
  
  borderPen := new Pen(Color.FromArgb(150, 150, 154), 2);
  try
    DrawRoundedRectangle(g, borderPen, nodeRect, 8);
  finally
    borderPen.Dispose();
  end;
  
  font := new System.Drawing.Font('Segoe UI', 11, FontStyle.Bold);
  textBrush := new SolidBrush(Color.White);
  try
    format := new StringFormat();
    format.Alignment := StringAlignment.Center;
    format.LineAlignment := StringAlignment.Near;
    
    titleRect := new Rectangle(nodeRect.X, nodeRect.Y + 8, nodeRect.Width, 25);
    g.DrawString(node.Title, font, textBrush, titleRect, format);
  finally
    font.Dispose();
    textBrush.Dispose();
    format.Dispose();
  end;
  
  DrawNodeImages(g, node, nodeRect);
  DrawNodePorts(g, node, nodeRect);
end;

procedure NodeCanvas.DrawNodeImages(g: Graphics; node: Node; nodeRect: Rectangle);
var
  imageY, imageSize, spacing, inputImagesPerRow, inputRowHeight: integer;
  outputImagesPerRow, outputRowHeight, i, row, col, x, y: integer;
  imgRect, gifRect: Rectangle;
  font, nameFont: System.Drawing.Font;
  textBrush, nameBrush: SolidBrush;
  imageName: string;
  hasGifInOutput: boolean;
  gifIndex, normalImageCount, gifRowsUsed, gifY, gifSize: integer;
begin
  imageY := nodeRect.Y + 35;
  imageSize := 60;
  spacing := 5;
  
  // Input 이미지들 표시
  if (node.InputImages <> nil) and (node.InputImages.Count > 0) then
  begin
    font := new System.Drawing.Font('Segoe UI', 8, FontStyle.Bold);
    textBrush := new SolidBrush(Color.LightBlue);
    try
      g.DrawString('INPUT', font, textBrush, nodeRect.X + 10, imageY - 15);
    finally
      font.Dispose();
      textBrush.Dispose();
    end;
    
    inputImagesPerRow := Min(4, node.InputImages.Count);
    inputRowHeight := imageSize + spacing;
    
    for i := 0 to node.InputImages.Count - 1 do
    begin
      row := i div inputImagesPerRow;
      col := i mod inputImagesPerRow;
      
      x := nodeRect.X + 10 + col * (imageSize + spacing);
      y := imageY + row * inputRowHeight;
      
      imgRect := new Rectangle(x, y, imageSize, imageSize);
      
      if node.InputImages[i] <> nil then
      begin
        // GIF 애니메이션 등록 (중복 등록 방지)
        if IsAnimatedGif(node.InputImages[i]) and (not animatedImages.ContainsKey(node.InputImages[i])) then
        begin
          ImageAnimator.Animate(node.InputImages[i], OnFrameChanged);
          animatedImages[node.InputImages[i]] := true;
        end;
        
        // 현재 프레임 그리기
        g.DrawImage(node.InputImages[i], imgRect);
        
        if i < node.InputImageNames.Count then
          imageName := node.InputImageNames[i]
        else
          imageName := '';
          
        if imageName <> '' then
        begin
          nameFont := new System.Drawing.Font('Segoe UI', 6);
          nameBrush := new SolidBrush(Color.White);
          try
            g.DrawString(Path.GetFileNameWithoutExtension(imageName), nameFont, nameBrush, x, y + imageSize + 2);
          finally
            nameFont.Dispose();
            nameBrush.Dispose();
          end;
        end;
      end
      else
      begin
        g.FillRectangle(Brushes.DarkGray, imgRect);
        g.DrawRectangle(Pens.Gray, imgRect);
      end;
    end;
    
    imageY := imageY + ((node.InputImages.Count - 1) div inputImagesPerRow + 1) * inputRowHeight + 20;
  end;
  
  // Output 이미지들 표시
  if (node.OutputImages <> nil) and (node.OutputImages.Count > 0) then
  begin
    font := new System.Drawing.Font('Segoe UI', 8, FontStyle.Bold);
    textBrush := new SolidBrush(Color.Orange);
    try
      g.DrawString('OUTPUT', font, textBrush, nodeRect.X + 10, imageY - 15);
    finally
      font.Dispose();
      textBrush.Dispose();
    end;
    
    // Step04와 Step05의 GIF 이미지 확대를 위한 계산
    hasGifInOutput := false;
    gifIndex := -1;
    
    // GIF 파일이 있는지 확인
    if (node.NodeType = TNodeType.Step04) or (node.NodeType = TNodeType.Step05) then
    begin
      for i := 0 to node.OutputImages.Count - 1 do
      begin
        if (node.OutputImages[i] <> nil) and IsAnimatedGif(node.OutputImages[i]) then
        begin
          hasGifInOutput := true;
          gifIndex := i;
          break;
        end;
      end;
    end;
    
    outputImagesPerRow := Min(4, node.OutputImages.Count);
    outputRowHeight := imageSize + spacing;
    
    // GIF가 있는 경우 레이아웃 조정
    if hasGifInOutput then
    begin
      // 일반 이미지들 먼저 표시 (GIF 제외)
      normalImageCount := 0;
      for i := 0 to node.OutputImages.Count - 1 do
      begin
        if i = gifIndex then continue; // GIF는 나중에 표시
        
        row := normalImageCount div outputImagesPerRow;
        col := normalImageCount mod outputImagesPerRow;
        
        x := nodeRect.X + 10 + col * (imageSize + spacing);
        y := imageY + row * outputRowHeight;
        
        imgRect := new Rectangle(x, y, imageSize, imageSize);
        
        if node.OutputImages[i] <> nil then
        begin
          // 현재 프레임 그리기
          g.DrawImage(node.OutputImages[i], imgRect);
          
          if i < node.OutputImageNames.Count then
            imageName := node.OutputImageNames[i]
          else
            imageName := '';
            
          if imageName <> '' then
          begin
            nameFont := new System.Drawing.Font('Segoe UI', 6);
            nameBrush := new SolidBrush(Color.White);
            try
              g.DrawString(Path.GetFileNameWithoutExtension(imageName), nameFont, nameBrush, x, y + imageSize + 2);
            finally
              nameFont.Dispose();
              nameBrush.Dispose();
            end;
          end;
        end
        else
        begin
          g.FillRectangle(Brushes.DarkGray, imgRect);
          g.DrawRectangle(Pens.Gray, imgRect);
        end;
        
        Inc(normalImageCount);
      end;
      
      // 일반 이미지들 다음 줄에 GIF를 3배 크기로 표시
      if normalImageCount > 0 then
        gifRowsUsed := (normalImageCount - 1) div outputImagesPerRow + 1
      else
        gifRowsUsed := 0;
        
      gifY := imageY + gifRowsUsed * outputRowHeight + 10; // 약간의 여백 추가
      
      // GIF 크기 3배 (180x180)
      gifSize := imageSize * 3;
      gifRect := new Rectangle(nodeRect.X + 10, gifY, gifSize, gifSize);
      
      if node.OutputImages[gifIndex] <> nil then
      begin
        // GIF 애니메이션 등록 (중복 등록 방지)
        if not animatedImages.ContainsKey(node.OutputImages[gifIndex]) then
        begin
          ImageAnimator.Animate(node.OutputImages[gifIndex], OnFrameChanged);
          animatedImages[node.OutputImages[gifIndex]] := true;
        end;
        
        // 3배 크기로 GIF 그리기
        g.DrawImage(node.OutputImages[gifIndex], gifRect);
        
        if gifIndex < node.OutputImageNames.Count then
          imageName := node.OutputImageNames[gifIndex]
        else
          imageName := '';
          
        if imageName <> '' then
        begin
          nameFont := new System.Drawing.Font('Segoe UI', 8, FontStyle.Bold); // 폰트도 크게
          nameBrush := new SolidBrush(Color.Yellow); // 노란색으로 강조
          try
            g.DrawString(Path.GetFileNameWithoutExtension(imageName), nameFont, nameBrush, gifRect.X, gifRect.Y + gifSize + 5);
          finally
            nameFont.Dispose();
            nameBrush.Dispose();
          end;
        end;
      end;
    end
    else
    begin
      // GIF가 없는 경우 기존 방식으로 표시
      for i := 0 to node.OutputImages.Count - 1 do
      begin
        row := i div outputImagesPerRow;
        col := i mod outputImagesPerRow;
        
        x := nodeRect.X + 10 + col * (imageSize + spacing);
        y := imageY + row * outputRowHeight;
        
        imgRect := new Rectangle(x, y, imageSize, imageSize);
        
        if node.OutputImages[i] <> nil then
        begin
          // GIF 애니메이션 등록 (중복 등록 방지)
          if IsAnimatedGif(node.OutputImages[i]) and (not animatedImages.ContainsKey(node.OutputImages[i])) then
          begin
            ImageAnimator.Animate(node.OutputImages[i], OnFrameChanged);
            animatedImages[node.OutputImages[i]] := true;
          end;
          
          // 현재 프레임 그리기
          g.DrawImage(node.OutputImages[i], imgRect);
          
          if i < node.OutputImageNames.Count then
            imageName := node.OutputImageNames[i]
          else
            imageName := '';
            
          if imageName <> '' then
          begin
            nameFont := new System.Drawing.Font('Segoe UI', 6);
            nameBrush := new SolidBrush(Color.White);
            try
              g.DrawString(Path.GetFileNameWithoutExtension(imageName), nameFont, nameBrush, x, y + imageSize + 2);
            finally
              nameFont.Dispose();
              nameBrush.Dispose();
            end;
          end;
        end
        else
        begin
          g.FillRectangle(Brushes.DarkGray, imgRect);
          g.DrawRectangle(Pens.Gray, imgRect);
        end;
      end;
    end;
  end;
end;

// DrawNodePorts 구현
procedure NodeCanvas.DrawNodePorts(g: Graphics; node: Node; nodeRect: Rectangle);
var
  portY: integer;
  port: NodePort;
  font: System.Drawing.Font;
  textBrush: SolidBrush;
  textSize: SizeF;
begin
  portY := nodeRect.Bottom - 30;
  
  for var i := 0 to node.InputPorts.Count - 1 do
  begin
    port := node.InputPorts[i];
    DrawPort(g, port, new Point(nodeRect.X - 8, portY));
    
    font := new System.Drawing.Font('Segoe UI', 9);
    textBrush := new SolidBrush(Color.LightGray);
    try
      g.DrawString(port.Name, font, textBrush, nodeRect.X + 15, portY - 8);
    finally
      font.Dispose();
      textBrush.Dispose();
    end;
  end;
  
  for var i := 0 to node.OutputPorts.Count - 1 do
  begin
    port := node.OutputPorts[i];
    DrawPort(g, port, new Point(nodeRect.Right - 8, portY));
    
    font := new System.Drawing.Font('Segoe UI', 9);
    textBrush := new SolidBrush(Color.LightGray);
    try
      textSize := g.MeasureString(port.Name, font);
      g.DrawString(port.Name, font, textBrush, nodeRect.Right - textSize.Width - 15, portY - 8);
    finally
      font.Dispose();
      textBrush.Dispose();
    end;
  end;
end;

// DrawPort 구현
procedure NodeCanvas.DrawPort(g: Graphics; port: NodePort; position: Point);
var
  portRect: Rectangle;
  portColor: Color;
  brush: SolidBrush;
  pen: Pen;
begin
  portRect := new Rectangle(position.X - 8, position.Y - 8, 16, 16);
  port.Bounds := portRect;
  
  if port.PortType = TPortType.Input then
    portColor := Color.LightBlue
  else
    portColor := Color.Orange;
  
  brush := new SolidBrush(portColor);
  try
    g.FillEllipse(brush, portRect);
  finally
    brush.Dispose();
  end;
  
  pen := new System.Drawing.Pen(Color.White, 2);
  try
    g.DrawEllipse(pen, portRect);
  finally
    pen.Dispose();
  end;
end;

// DrawConnection 구현
procedure NodeCanvas.DrawConnection(g: Graphics; connection: Connection);
var
  startPos, endPos: Point;
  isHighlighted: boolean;
  connectionColor: Color;
  lineWidth: integer;
begin
  startPos := GetPortCenter(connection.OutputPort);
  endPos := GetPortCenter(connection.InputPort);
  
  isHighlighted := IsConnectionNearMouse(connection, lastMousePos);
  if isHighlighted then
  begin
    connectionColor := Color.Red;
    lineWidth := 4;
  end
  else
  begin
    connectionColor := Color.Yellow;
    lineWidth := 3;
  end;
  
  DrawBezierConnection(g, startPos, endPos, connectionColor, lineWidth);
end;

// DrawTempConnection 구현
procedure NodeCanvas.DrawTempConnection(g: Graphics; startPort: NodePort; mousePos: Point);
var
  startPos, endPos: Point;
begin
  startPos := GetPortCenter(startPort);
  endPos := new Point(
    Round((mousePos.X - canvasOffset.X) / zoomLevel),
    Round((mousePos.Y - canvasOffset.Y) / zoomLevel)
  );
  
  DrawBezierConnection(g, startPos, endPos, Color.Gray, 2);
end;

// DrawBezierConnection 구현
procedure NodeCanvas.DrawBezierConnection(g: Graphics; startPos, endPos: Point; color: Color; lineWidth: integer); //lineWidth: integer := 3
var
  pen: Pen;
  controlOffset: integer;
  control1, control2: Point;
begin
  pen := new System.Drawing.Pen(color, lineWidth);
  try
    controlOffset := Abs(endPos.X - startPos.X) div 2;
    control1 := new Point(startPos.X + controlOffset, startPos.Y);
    control2 := new Point(endPos.X - controlOffset, endPos.Y);
    
    g.DrawBezier(pen, startPos, control1, control2, endPos);
  finally
    pen.Dispose();
  end;
end;

// GetPortCenter 구현
function NodeCanvas.GetPortCenter(port: NodePort): Point;
begin
  Result := new Point(
    port.Bounds.X + port.Bounds.Width div 2,
    port.Bounds.Y + port.Bounds.Height div 2
  );
end;

// GetNodeAtPosition 구현
function NodeCanvas.GetNodeAtPosition(position: Point): Node;
var
  adjustedPos: Point;
  i, nodeWidth, nodeHeight: integer;
  nodeRect: Rectangle;
begin
  Result := nil;
  
  adjustedPos := new Point(
    Round((position.X - canvasOffset.X) / zoomLevel),
    Round((position.Y - canvasOffset.Y) / zoomLevel)
  );
  
  for i := nodes.Count - 1 downto 0 do
  begin
    nodeWidth := GetNodeWidth(nodes[i]);
    nodeHeight := GetNodeHeight(nodes[i]);
    nodeRect := new Rectangle(nodes[i].Position.X, nodes[i].Position.Y, nodeWidth, nodeHeight);
    if nodeRect.Contains(adjustedPos) then
    begin
      Result := nodes[i];
      exit;
    end;
  end;
end;

// GetPortAtPosition 구현
function NodeCanvas.GetPortAtPosition(position: Point): NodePort;
var
  adjustedPos: Point;
  node: Node;
  port: NodePort;
begin
  Result := nil;
  
  adjustedPos := new Point(
    Round((position.X - canvasOffset.X) / zoomLevel),
    Round((position.Y - canvasOffset.Y) / zoomLevel)
  );
  
  for var i := 0 to nodes.Count - 1 do
  begin
    node := nodes[i];
    for var j := 0 to node.InputPorts.Count - 1 do
    begin
      port := node.InputPorts[j];
      if port.Bounds.Contains(adjustedPos) then
      begin
        Result := port;
        exit;
      end;
    end;
    
    for var j := 0 to node.OutputPorts.Count - 1 do
    begin
      port := node.OutputPorts[j];
      if port.Bounds.Contains(adjustedPos) then
      begin
        Result := port;
        exit;
      end;
    end;
  end;
end;


// GetConnectionAtPosition 구현
function NodeCanvas.GetConnectionAtPosition(position: Point): Connection;
var
  adjustedPos: Point;
  connection: Connection;
begin
  Result := nil;
  
  adjustedPos := new Point(
    Round((position.X - canvasOffset.X) / zoomLevel),
    Round((position.Y - canvasOffset.Y) / zoomLevel)
  );
  
  for var i := 0 to connections.Count - 1 do
  begin
    connection := connections[i];
    if IsPointOnConnection(connection, adjustedPos) then
    begin
      Result := connection;
      exit;
    end;
  end;
end;

// IsPointOnConnection 구현
function NodeCanvas.IsPointOnConnection(connection: Connection; point: Point): boolean;
var
  startPos, endPos, control1, control2, bezierPoint: System.Drawing.Point;
  controlOffset, i: integer;
  t, distance: real;
const
  segments = 20;
  threshold = 10.0;
begin
  Result := false;
  
  startPos := GetPortCenter(connection.OutputPort);
  endPos := GetPortCenter(connection.InputPort);
  
  controlOffset := Abs(endPos.X - startPos.X) div 2;
  control1 := new System.Drawing.Point(startPos.X + controlOffset, startPos.Y);
  control2 := new System.Drawing.Point(endPos.X - controlOffset, endPos.Y);
  
  for i := 0 to segments do
  begin
    t := i / segments;
    bezierPoint := CalculateBezierPoint(startPos, control1, control2, endPos, t);
    
    distance := Sqrt(Sqr(point.X - bezierPoint.X) + Sqr(point.Y - bezierPoint.Y));
    if distance <= threshold then
    begin
      Result := true;
      exit;
    end;
  end;
end;

// IsConnectionNearMouse 구현
function NodeCanvas.IsConnectionNearMouse(connection: Connection; mousePos: Point): boolean;
var
  adjustedPos: Point;
begin
  adjustedPos := new Point(
    Round((mousePos.X - canvasOffset.X) / zoomLevel),
    Round((mousePos.Y - canvasOffset.Y) / zoomLevel)
  );
  
  Result := IsPointOnConnection(connection, adjustedPos);
end;


// CalculateBezierPoint 구현
function NodeCanvas.CalculateBezierPoint(p0, p1, p2, p3: Point; t: real): Point;
var
  u, tt, uu, uuu, ttt: real;
  x, y: real;
begin
  u := 1 - t;
  tt := t * t;
  uu := u * u;
  uuu := uu * u;
  ttt := tt * t;
  
  x := uuu * p0.X + 3 * uu * t * p1.X + 3 * u * tt * p2.X + ttt * p3.X;
  y := uuu * p0.Y + 3 * uu * t * p1.Y + 3 * u * tt * p2.Y + ttt * p3.Y;
  
  Result := new Point(Round(x), Round(y));
end;


// CanConnect 구현
function NodeCanvas.CanConnect(port1, port2: NodePort): boolean;
var
  connection: Connection;
begin
  Result := (port1.PortType <> port2.PortType);
  
  if Result then
  begin
    for var i := 0 to connections.Count - 1 do
    begin
      connection := connections[i];
      if ((connection.OutputPort = port1) and (connection.InputPort = port2)) or
         ((connection.OutputPort = port2) and (connection.InputPort = port1)) then
      begin
        Result := false;
        exit;
      end;
    end;
  end;
end;


// ProcessImageFlow 구현
procedure NodeCanvas.ProcessImageFlow(outputPort, inputPort: NodePort);
var
  fromPort, toPort: NodePort;
  fromNode, toNode: Node;
begin
  if outputPort.PortType = TPortType.Output then
  begin
    fromPort := outputPort;
    toPort := inputPort;
  end
  else
  begin
    fromPort := inputPort;
    toPort := outputPort;
  end;
  
  fromNode := fromPort.ParentNode;
  toNode := toPort.ParentNode;
  
  ProcessSpecificNodeConnection(fromNode, toNode);
  Self.Invalidate();
end;


// RemoveConnection 구현
procedure NodeCanvas.RemoveConnection(connection: Connection);
begin
  if connections.Contains(connection) then
  begin
    connections.Remove(connection);
    ResetNodeAfterDisconnection(connection.InputPort.ParentNode);
    UpdateStatusMessage('연결이 제거되었습니다: ' + connection.OutputPort.ParentNode.Title + '→' + connection.InputPort.ParentNode.Title);
  end;
end;

// UpdateStatusMessage 구현
procedure NodeCanvas.UpdateStatusMessage(message: string);
var
  parent: Control;
  parentForm: Form;
  statusStrip: StatusStrip;
  statusLabel: ToolStripStatusLabel;
  control: Control;
  item: ToolStripItem;
begin
  parent := Self.Parent;
  while (parent <> nil) and not (parent is Form) do
    parent := parent.Parent;
  
  parentForm := parent as Form;
  if parentForm <> nil then
  begin
    statusStrip := nil;
    for var i := 0 to parentForm.Controls.Count - 1 do
    begin
      control := parentForm.Controls[i];
      if control is System.Windows.Forms.StatusStrip then
      begin
        statusStrip := control as System.Windows.Forms.StatusStrip;
        break;
      end;
    end;
    
    if statusStrip <> nil then
    begin
      statusLabel := nil;
      for var i := 0 to statusStrip.Items.Count - 1 do
      begin
        item := statusStrip.Items[i];
        if item is ToolStripStatusLabel then
        begin
          statusLabel := item as ToolStripStatusLabel;
          break;
        end;
      end;
      
      if statusLabel <> nil then
        statusLabel.Text := message;
    end;
  end;
end;

// ResetNodeAfterDisconnection 구현
procedure NodeCanvas.ResetNodeAfterDisconnection(node: Node);
var
  hasOutputConnection: boolean;
  connection: Connection;
begin
  node.InputImages.Clear();
  node.InputImageNames.Clear();
  
  hasOutputConnection := false;
  for var i := 0 to connections.Count - 1 do
  begin
    connection := connections[i];
    if connection.OutputPort.ParentNode = node then
    begin
      hasOutputConnection := true;
      break;
    end;
  end;
  
  if (not hasOutputConnection) and (node.NodeType <> TNodeType.Original) then
  begin
    node.OutputImages.Clear();
    node.OutputImageNames.Clear();
  end;
end;


// ResetAllNodes 구현
procedure NodeCanvas.ResetAllNodes;
var
  node: Node;
begin
  connections.Clear();
  
  for var i := 0 to nodes.Count - 1 do
  begin
    node := nodes[i];
    node.InputImages.Clear();
    node.InputImageNames.Clear();
    node.OutputImages.Clear();
    node.OutputImageNames.Clear();
    
    if node.NodeType = TNodeType.Original then
      node.LoadImages(['input.png'], false);
  end;
  
  Self.Invalidate();
end;



// Drawing 메서드들과 기타 유틸리티 메서드들...
procedure NodeCanvas.ProcessSpecificNodeConnection(fromNode, toNode: Node);
var
  selectedImages: List<Image>;
  selectedNames: List<string>;
  combinedImages: List<Image>;
  combinedNames: List<string>;
  emojiImage: Image;
  emojiPath, relativePath: string;
  step04Outputs: array of string;
  i: integer;
begin
  case toNode.NodeType of
    TNodeType.Step01:
      if fromNode.NodeType = TNodeType.Original then
      begin
        toNode.SetInputImages(fromNode.OutputImages, fromNode.OutputImageNames);
        toNode.LoadImages(['images/debug_full_mask.png', 'images/background.png', 'images/output_no_bg.png'], false);
      end;
      
    TNodeType.Step02:
      if fromNode.NodeType = TNodeType.Step01 then
      begin
        selectedImages := new List<Image>;
        selectedNames := new List<string>;
        
        if fromNode.OutputImages.Count >= 2 then
        begin
          selectedImages.Add(fromNode.OutputImages[0]);
          selectedImages.Add(fromNode.OutputImages[1]);
          selectedNames.Add('images/debug_full_mask.png');
          selectedNames.Add('images/background.png');
        end;
        
        toNode.SetInputImages(selectedImages, selectedNames);
        toNode.LoadImages(['images/lama_output.png'], false);
      end;
      
    TNodeType.Step03:
      if fromNode.NodeType = TNodeType.Original then
      begin
        combinedImages := new List<Image>(fromNode.OutputImages);
        if fromNode.OutputImageNames <> nil then
          combinedNames := new List<string>(fromNode.OutputImageNames)
        else
          combinedNames := new List<string>;
        
        // emoji_rabbit.png 이미지 로드
        emojiPath := 'images/emoji_rabbit.png';
        
        try
          if System.IO.File.Exists(emojiPath) then
          begin
            emojiImage := Image.FromFile(emojiPath);
          end
          else
          begin
            // 상대 경로로도 시도
            relativePath := Path.Combine(Application.StartupPath, emojiPath);
            if System.IO.File.Exists(relativePath) then
            begin
              emojiImage := Image.FromFile(relativePath);
            end
            else
            begin
              // 파일이 없으면 플레이스홀더 생성
              emojiImage := fromNode.CreatePlaceholderImage('emoji_rabbit.png', Color.Yellow);
            end;
          end;
        except
          // 오류 발생 시 플레이스홀더 생성
          emojiImage := fromNode.CreatePlaceholderImage('emoji_rabbit.png', Color.Yellow);
        end;
        
        combinedImages.Add(emojiImage);
        combinedNames.Add('emoji_rabbit.png');
        
        toNode.SetInputImages(combinedImages, combinedNames);
        toNode.LoadImages(['images/output.png'], false);
      end;
      
    TNodeType.Step04:
      if fromNode.NodeType = TNodeType.Step01 then
      begin
        selectedImages := new List<Image>;
        selectedNames := new List<string>;
        
        if fromNode.OutputImages.Count >= 3 then
        begin
          selectedImages.Add(fromNode.OutputImages[2]);
          selectedNames.Add('images/output_no_bg.png');
        end;
        
        toNode.SetInputImages(selectedImages, selectedNames);
        
        step04Outputs := [
          'images/360_view_001_000deg_from_000deg.png',
          'images/360_view_002_045deg_from_060deg.png',
          'images/360_view_003_090deg_from_090deg.png',
          'images/360_view_004_135deg_from_090deg.png',
          'images/360_view_005_180deg_from_180deg.png',
          'images/360_view_006_225deg_from_240deg.png',
          'images/360_view_007_270deg_from_270deg.png',
          'images/360_view_008_315deg_from_000deg.png',
          'images/ultrafast_360.gif'
        ];
        
        toNode.LoadImages(step04Outputs, false);
      end;
      
    TNodeType.Step05:
      if fromNode.NodeType = TNodeType.Step04 then
      begin
        selectedImages := new List<Image>;
        selectedNames := new List<string>;
        
        if fromNode.OutputImages.Count >= 8 then
        begin
          for i := 0 to 7 do
          begin
            selectedImages.Add(fromNode.OutputImages[i]);
            selectedNames.Add(fromNode.OutputImageNames[i]);
          end;
        end;
        
        toNode.SetInputImages(selectedImages, selectedNames);
        toNode.LoadImages(['images/step05_sc_2025-08-11.gif'], false);
      end;
  end;
end;

// 기타 필요한 메서드들 (간략화)
procedure NodeCanvas.ClearAllConnections;
begin
  connections.Clear();
  for var i := 0 to nodes.Count - 1 do
  begin
    if nodes[i].NodeType <> TNodeType.Original then
    begin
      nodes[i].InputImages.Clear();
      nodes[i].InputImageNames.Clear();
      nodes[i].OutputImages.Clear();
      nodes[i].OutputImageNames.Clear();
    end;
  end;
  Self.Invalidate();
end;

// Form1 implementation
constructor Form1.Create;
begin
  inherited Create;
  InitializeComponent();
  menuStrip := new System.Windows.Forms.MenuStrip();
  InitUI();
end;

procedure Form1.InitUI;
begin  
  Self.Text := '이미지 처리 워크플로우 - Node Based UI';
  Self.Size := new System.Drawing.Size(1400, 900);
  Self.StartPosition := FormStartPosition.CenterScreen;
  Self.WindowState := FormWindowState.Maximized;
  
  CreateMenuStrip();
  
  canvas := new NodeCanvas();
  canvas.Dock := DockStyle.Fill;
  Self.Controls.Add(canvas);
  
  CreateStatusBar();
end;

procedure Form1.CreateMenuStrip;
var
  fileMenu, editMenu, viewMenu, helpMenu: ToolStripMenuItem;
  loadImageItem, saveAllItem, exitItem: ToolStripMenuItem;
  clearAllConnectionsItem, resetAllNodesItem: ToolStripMenuItem;
  resetViewItem, fitToScreenItem, aboutItem: ToolStripMenuItem;
begin
  // 파일 메뉴
  fileMenu := new ToolStripMenuItem('파일');
  
  loadImageItem := new ToolStripMenuItem('원본 이미지 로드');
  loadImageItem.Click += LoadImageItem_Click;
  
  saveAllItem := new ToolStripMenuItem('모든 결과 저장');
  saveAllItem.Click += SaveAllItem_Click;
  
  exitItem := new ToolStripMenuItem('종료');
  exitItem.Click += ExitItem_Click;
  
  fileMenu.DropDownItems.Add(loadImageItem);
  fileMenu.DropDownItems.Add(new ToolStripSeparator());
  fileMenu.DropDownItems.Add(saveAllItem);
  fileMenu.DropDownItems.Add(new ToolStripSeparator());
  fileMenu.DropDownItems.Add(exitItem);
  
  // 편집 메뉴
  editMenu := new ToolStripMenuItem('편집');
  
  clearAllConnectionsItem := new ToolStripMenuItem('모든 연결 제거');
  clearAllConnectionsItem.Click += ClearAllConnectionsItem_Click;
  
  resetAllNodesItem := new ToolStripMenuItem('모든 노드 리셋');
  resetAllNodesItem.Click += ResetAllNodesItem_Click;
  
  editMenu.DropDownItems.Add(clearAllConnectionsItem);
  editMenu.DropDownItems.Add(resetAllNodesItem);
  
  // 보기 메뉴
  viewMenu := new ToolStripMenuItem('보기');
  
  resetViewItem := new ToolStripMenuItem('뷰 리셋');
  resetViewItem.Click += ResetViewItem_Click;
  
  fitToScreenItem := new ToolStripMenuItem('화면에 맞춤');
  fitToScreenItem.Click += FitToScreenItem_Click;
  
  viewMenu.DropDownItems.Add(resetViewItem);
  viewMenu.DropDownItems.Add(fitToScreenItem);
  
  // 도움말 메뉴
  helpMenu := new ToolStripMenuItem('도움말');
  
  aboutItem := new ToolStripMenuItem('정보');
  aboutItem.Click += AboutItem_Click;
  
  helpMenu.DropDownItems.Add(aboutItem);
  
  menuStrip.Items.Add(fileMenu);
  menuStrip.Items.Add(editMenu);
  menuStrip.Items.Add(viewMenu);
  menuStrip.Items.Add(helpMenu);
  
  Self.MainMenuStrip := menuStrip;
  Self.Controls.Add(menuStrip);
end;

procedure Form1.CreateStatusBar;
var
  statusStrip: StatusStrip;
  statusLabel, nodeCountLabel: ToolStripStatusLabel;
begin
  statusStrip := new System.Windows.Forms.StatusStrip();
  
  statusLabel := new ToolStripStatusLabel();
  statusLabel.Text := '준비됨 - 노드를 연결하여 이미지 처리 워크플로우를 시작하세요';
  statusLabel.Spring := true;
  statusLabel.TextAlign := ContentAlignment.MiddleLeft;
  
  nodeCountLabel := new ToolStripStatusLabel();
  nodeCountLabel.Text := '노드: ' + canvas.TNodes.Count.ToString() + '개';
  
  statusStrip.Items.Add(statusLabel);
  statusStrip.Items.Add(nodeCountLabel);
  
  Self.Controls.Add(statusStrip);
end;

procedure Form1.LoadImageItem_Click(sender: Object; e: EventArgs);
var
  dialog: OpenFileDialog;
  originalNode: Node;
  loadedImage: Image;
begin
  dialog := new OpenFileDialog();
  try
    dialog.Filter := '이미지 파일|*.jpg;*.jpeg;*.png;*.bmp;*.gif|모든 파일|*.*';
    dialog.Title := '원본 이미지 선택';
    
    if dialog.ShowDialog() = System.Windows.Forms.DialogResult.OK then
    begin
      try
        originalNode := nil;
        for var i := 0 to canvas.TNodes.Count - 1 do
        begin
          if canvas.TNodes[i].NodeType = TNodeType.Original then
          begin
            originalNode := canvas.TNodes[i];
            break;
          end;
        end;
        
        if originalNode <> nil then
        begin
          originalNode.OutputImages.Clear();
          originalNode.OutputImageNames.Clear();
          
          loadedImage := Image.FromFile(dialog.FileName);
          originalNode.OutputImages.Add(loadedImage);
          originalNode.OutputImageNames.Add(Path.GetFileName(dialog.FileName));
          
          canvas.Invalidate();
          
          MessageBox.Show('이미지가 로드되었습니다: ' + Path.GetFileName(dialog.FileName), 
                        '로드 완료', MessageBoxButtons.OK, MessageBoxIcon.Information);
        end;
      except
        on ex: Exception do
        begin
          MessageBox.Show('이미지 로드 중 오류가 발생했습니다:'#13#10 + ex.Message, 
                        '오류', MessageBoxButtons.OK, MessageBoxIcon.Error);
        end;
      end;
    end;
  finally
    dialog.Dispose();
  end;
end;

procedure Form1.AboutItem_Click(sender: Object; e: EventArgs);
begin
  MessageBox.Show(
    '이미지 처리 워크플로우 시스템'#13#10#13#10 +
    '사용법:'#13#10 +
    '1. 노드를 드래그하여 이동'#13#10 +
    '2. 출력 포트에서 입력 포트로 연결'#13#10 +
    '3. 연결선을 우클릭하여 제거'#13#10 +
    '4. 마우스 휠로 확대/축소'#13#10 +
    '5. 가운데 버튼으로 캔버스 이동'#13#10#13#10 +
    '각 단계별로 이미지가 자동 처리됩니다.',
    '정보', MessageBoxButtons.OK, MessageBoxIcon.Information);
end;

procedure Form1.ExitItem_Click(sender: Object; e: EventArgs);
begin
  Self.Close();
end;

// 기타 이벤트 핸들러들은 비슷한 패턴으로 구현...
procedure Form1.SaveAllItem_Click(sender: Object; e: EventArgs);
begin
  // 이미지 저장 로직
end;

procedure Form1.ClearAllConnectionsItem_Click(sender: Object; e: EventArgs);
begin
  if MessageBox.Show('모든 연결을 제거하시겠습니까?', '확인', 
                    MessageBoxButtons.YesNo, MessageBoxIcon.Question) = System.Windows.Forms.DialogResult.Yes then
    canvas.ClearAllConnections();
end;

procedure Form1.ResetAllNodesItem_Click(sender: Object; e: EventArgs);
begin
  // 노드 리셋 로직
end;

procedure Form1.ResetViewItem_Click(sender: Object; e: EventArgs);
begin
  canvas.Invalidate();
end;

procedure Form1.FitToScreenItem_Click(sender: Object; e: EventArgs);
begin
  canvas.Invalidate();
end;

// Helper functions for rounded rectangles
procedure FillRoundedRectangle(g: Graphics; brush: Brush; rect: Rectangle; radius: integer);
var
  path: GraphicsPath;
begin
  path := CreateRoundedRectanglePath(rect, radius);
  try
    g.FillPath(brush, path);
  finally
    path.Dispose();
  end;
end;

procedure DrawRoundedRectangle(g: Graphics; pen: Pen; rect: Rectangle; radius: integer);
var
  path: GraphicsPath;
begin
  path := CreateRoundedRectanglePath(rect, radius);
  try
    g.DrawPath(pen, path);
  finally
    path.Dispose();
  end;
end;

function CreateRoundedRectanglePath(rect: Rectangle; radius: integer): GraphicsPath;
var
  path: GraphicsPath;
begin
  path := new GraphicsPath();
  path.StartFigure();
  path.AddArc(rect.X, rect.Y, radius, radius, 180, 90);
  path.AddArc(rect.Right - radius, rect.Y, radius, radius, 270, 90);
  path.AddArc(rect.Right - radius, rect.Bottom - radius, radius, radius, 0, 90);
  path.AddArc(rect.X, rect.Bottom - radius, radius, radius, 90, 90);
  path.CloseFigure();
  Result := path;
end;

end.