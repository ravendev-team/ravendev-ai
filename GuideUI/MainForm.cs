/*
 * Created by SharpDevelop.
 * User: dwfree74@naver.com
 * Date: 2025-08-13
 * Time: 오전 1:57
 * 
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Linq;
using System.Windows.Forms;
using System.IO;

namespace NodeBasedGuideUI
{
    public partial class NodeCanvas : UserControl
    {
        private List<Node> nodes = new List<Node>();
        private List<Connection> connections = new List<Connection>();
        private Node draggedNode = null;
        private NodePort connectionStartPort = null;
        private Point lastMousePos;
        private Point canvasOffset = Point.Empty;
        private bool isPanning = false;
        private float zoomLevel = 1.0f;
        private Timer animationTimer;

        public List<Node> Nodes { get { return this.nodes; } }
        public List<Connection> Connections { get { return this.connections; } }

        public NodeCanvas()
        {
            InitializeComponent();
            SetStyle(ControlStyles.AllPaintingInWmPaint | 
                    ControlStyles.UserPaint | 
                    ControlStyles.DoubleBuffer | 
                    ControlStyles.ResizeRedraw, true);
            
            this.MouseDown += NodeCanvas_MouseDown;
            this.MouseMove += NodeCanvas_MouseMove;
            this.MouseUp += NodeCanvas_MouseUp;
            this.Paint += NodeCanvas_Paint;
            this.MouseWheel += NodeCanvas_MouseWheel;
            
            // GIF 애니메이션을 위한 타이머 설정
            animationTimer = new Timer();
            animationTimer.Interval = 100; // 100ms 간격으로 업데이트
            animationTimer.Tick += AnimationTimer_Tick;
            animationTimer.Start();
            
            AddProcessingNodes();
        }
        
        private void AnimationTimer_Tick(object sender, EventArgs e)
        {
            bool hasAnimatedImages = false;
            
            // 모든 노드의 이미지들을 확인하여 GIF 애니메이션 업데이트
            foreach (var node in nodes)
            {
                if (node.InputImages != null)
                {
                    foreach (var image in node.InputImages)
                    {
                        if (IsAnimatedGif(image))
                        {
                            ImageAnimator.UpdateFrames(image);
                            hasAnimatedImages = true;
                        }
                    }
                }
                
                if (node.OutputImages != null)
                {
                    foreach (var image in node.OutputImages)
                    {
                        if (IsAnimatedGif(image))
                        {
                            ImageAnimator.UpdateFrames(image);
                            hasAnimatedImages = true;
                        }
                    }
                }
            }
            
            // 애니메이션이 있는 경우에만 다시 그리기
            if (hasAnimatedImages)
            {
                this.Invalidate();
            }
        }
        
        private void InitializeComponent()
        {
            this.BackColor = Color.FromArgb(45, 45, 48);
            this.Size = new Size(1200, 800);
        }
        
        private void AddProcessingNodes()
        {
            // 원본 이미지 노드
            var originalNode = new Node("원본이미지", new Point(50, 30), NodeType.Original);
            originalNode.OutputPorts.Add(new NodePort("Output", PortType.Output, originalNode));
            originalNode.LoadImages(new string[] { "images/input.png" }, false);
            nodes.Add(originalNode);
            
            // Step01 노드
            var step01Node = new Node("Step01", new Point(300, 30), NodeType.Step01);
            step01Node.InputPorts.Add(new NodePort("Input", PortType.Input, step01Node));
            step01Node.OutputPorts.Add(new NodePort("Output", PortType.Output, step01Node));
            nodes.Add(step01Node);
            
            // Step02 노드
            var step02Node = new Node("Step02", new Point(600, 30), NodeType.Step02);
            step02Node.InputPorts.Add(new NodePort("Input", PortType.Input, step02Node));
            step02Node.OutputPorts.Add(new NodePort("Output", PortType.Output, step02Node));
            nodes.Add(step02Node);
            
            // Step03 노드
            var step03Node = new Node("Step03", new Point(300, 330), NodeType.Step03); //600, 200
            step03Node.InputPorts.Add(new NodePort("Input", PortType.Input, step03Node));
            step03Node.OutputPorts.Add(new NodePort("Output", PortType.Output, step03Node));
            nodes.Add(step03Node);
            
            // Step04 노드
            var step04Node = new Node("Step04", new Point(600, 330), NodeType.Step04); //300, 350
            step04Node.InputPorts.Add(new NodePort("Input", PortType.Input, step04Node));
            step04Node.OutputPorts.Add(new NodePort("Output", PortType.Output, step04Node));
            nodes.Add(step04Node);
            
            // Step05 노드
            var step05Node = new Node("Step05", new Point(900, 330), NodeType.Step05); //600, 450
            step05Node.InputPorts.Add(new NodePort("Input", PortType.Input, step05Node));
            step05Node.OutputPorts.Add(new NodePort("Output", PortType.Output, step05Node));
            nodes.Add(step05Node);
        }
        
        private void NodeCanvas_MouseDown(object sender, MouseEventArgs e)
        {
            lastMousePos = e.Location;
            
            if (e.Button == MouseButtons.Middle)
            {
                isPanning = true;
                return;
            }
            
            // 우클릭 시 연결선 제거 확인
            if (e.Button == MouseButtons.Right)
            {
                var clickedConnection = GetConnectionAtPosition(e.Location);
                if (clickedConnection != null)
                {
                    RemoveConnection(clickedConnection);
                    this.Invalidate();
                    return;
                }
                
                // 연결 생성 취소
                if (connectionStartPort != null)
                {
                    connectionStartPort = null;
                    this.Invalidate();
                    return;
                }
            }
            
            // 포트 클릭 확인
            var clickedPort = GetPortAtPosition(e.Location);
            if (clickedPort != null && e.Button == MouseButtons.Left)
            {
                if (connectionStartPort == null)
                {
                    connectionStartPort = clickedPort;
                }
                else
                {
                    // 연결 생성
                    if (CanConnect(connectionStartPort, clickedPort))
                    {
                        connections.Add(new Connection(connectionStartPort, clickedPort));
                        ProcessImageFlow(connectionStartPort, clickedPort);
                    }
                    connectionStartPort = null;
                }
                this.Invalidate();
                return;
            }
            
            // 노드 클릭 확인
            if (e.Button == MouseButtons.Left)
            {
                draggedNode = GetNodeAtPosition(e.Location);
                if (draggedNode != null)
                {
                    nodes.Remove(draggedNode);
                    nodes.Add(draggedNode);
                }
            }
        }
        
        private void NodeCanvas_MouseMove(object sender, MouseEventArgs e)
        {
            if (isPanning)
            {
                canvasOffset.X += e.X - lastMousePos.X;
                canvasOffset.Y += e.Y - lastMousePos.Y;
                this.Invalidate();
            }
            else if (draggedNode != null)
            {
                draggedNode.Position = new Point(
                    draggedNode.Position.X + e.X - lastMousePos.X,
                    draggedNode.Position.Y + e.Y - lastMousePos.Y
                );
                this.Invalidate();
            }
            else if (connectionStartPort != null)
            {
                this.Invalidate();
            }
            
            lastMousePos = e.Location;
        }
        
        private void NodeCanvas_MouseUp(object sender, MouseEventArgs e)
        {
            draggedNode = null;
            isPanning = false;
        }
        
        private void NodeCanvas_MouseWheel(object sender, MouseEventArgs e)
        {
            float oldZoom = zoomLevel;
            zoomLevel += e.Delta > 0 ? 0.1f : -0.1f;
            zoomLevel = Math.Max(0.1f, Math.Min(3.0f, zoomLevel));
            
            if (oldZoom != zoomLevel)
            {
                this.Invalidate();
            }
        }
        
        private void NodeCanvas_Paint(object sender, PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            
            g.TranslateTransform(canvasOffset.X, canvasOffset.Y);
            g.ScaleTransform(zoomLevel, zoomLevel);
            
            DrawGrid(g);
            
            foreach (var connection in connections)
            {
                DrawConnection(g, connection);
            }
            
            if (connectionStartPort != null)
            {
                DrawTempConnection(g, connectionStartPort, lastMousePos);
            }
            
            foreach (var node in nodes)
            {
                DrawNode(g, node);
            }
        }
        
        private void DrawGrid(Graphics g)
        {
            using (Pen gridPen = new Pen(Color.FromArgb(60, 60, 63), 1))
            {
                int gridSize = 20;
                int startX = -(canvasOffset.X % gridSize);
                int startY = -(canvasOffset.Y % gridSize);
                
                for (int x = startX; x < this.Width; x += gridSize)
                {
                    g.DrawLine(gridPen, x, 0, x, this.Height);
                }
                
                for (int y = startY; y < this.Height; y += gridSize)
                {
                    g.DrawLine(gridPen, 0, y, this.Width, y);
                }
            }
        }
        
        private void DrawNode(Graphics g, Node node)
        {
            int nodeWidth = GetNodeWidth(node);
            int nodeHeight = GetNodeHeight(node);
            Rectangle nodeRect = new Rectangle(node.Position.X, node.Position.Y, nodeWidth, nodeHeight);
            
            Color nodeColor = GetNodeColor(node.Type);
            
            
            // 안전한 색상 계산
            Color darkerColor = Color.FromArgb(
                Math.Max(0, nodeColor.R - 20),
                Math.Max(0, nodeColor.G - 20), 
                Math.Max(0, nodeColor.B - 20)
            );
            
            using (LinearGradientBrush brush = new LinearGradientBrush(
                nodeRect, nodeColor, darkerColor, 90f))
            {
                g.FillRoundedRectangle(brush, nodeRect, 8);
            }
            
            using (Pen borderPen = new Pen(Color.FromArgb(150, 150, 154), 2))
            {
                g.DrawRoundedRectangle(borderPen, nodeRect, 8);
            }
            
            using (Font font = new Font("Segoe UI", 11, FontStyle.Bold))
            using (SolidBrush textBrush = new SolidBrush(Color.White))
            {
                StringFormat format = new StringFormat();
                format.Alignment = StringAlignment.Center;
                format.LineAlignment = StringAlignment.Near;
                
                Rectangle titleRect = new Rectangle(nodeRect.X, nodeRect.Y + 8, nodeRect.Width, 25);
                g.DrawString(node.Title, font, textBrush, titleRect, format);
            }
            
            DrawNodeImages(g, node, nodeRect);
            DrawNodePorts(g, node, nodeRect);
        }
        
        private void DrawNodeImages(Graphics g, Node node, Rectangle nodeRect)
        {
            int imageY = nodeRect.Y + 35;
            int imageSize = 60;
            int spacing = 5;
            
            // Input 이미지들 표시
            if (node.InputImages != null && node.InputImages.Count > 0)
            {
                using (Font font = new Font("Segoe UI", 8, FontStyle.Bold))
                using (SolidBrush textBrush = new SolidBrush(Color.LightBlue))
                {
                    g.DrawString("INPUT", font, textBrush, nodeRect.X + 10, imageY - 15);
                }
                
                int inputImagesPerRow = Math.Min(4, node.InputImages.Count);
                int inputRowHeight = imageSize + spacing;
                
                for (int i = 0; i < node.InputImages.Count; i++)
                {
                    int row = i / inputImagesPerRow;
                    int col = i % inputImagesPerRow;
                    
                    int x = nodeRect.X + 10 + col * (imageSize + spacing);
                    int y = imageY + row * inputRowHeight;
                    
                    Rectangle imgRect = new Rectangle(x, y, imageSize, imageSize);
                    
                    if (node.InputImages[i] != null)
                    {
                        // GIF 애니메이션 시작
                        if (IsAnimatedGif(node.InputImages[i]))
                        {
                            ImageAnimator.Animate(node.InputImages[i], OnFrameChanged);
                        }
                        
                        g.DrawImage(node.InputImages[i], imgRect);
                        
                        string imageName = node.InputImageNames[i];
                        if (!string.IsNullOrEmpty(imageName))
                        {
                            using (Font nameFont = new Font("Segoe UI", 6))
                            using (SolidBrush nameBrush = new SolidBrush(Color.White))
                            {
                                g.DrawString(Path.GetFileNameWithoutExtension(imageName), 
                                           nameFont, nameBrush, x, y + imageSize + 2);
                            }
                        }
                    }
                    else
                    {
                        g.FillRectangle(Brushes.DarkGray, imgRect);
                        g.DrawRectangle(Pens.Gray, imgRect);
                    }
                }
                
                imageY += ((node.InputImages.Count - 1) / inputImagesPerRow + 1) * inputRowHeight + 20;
            }
            
            // Output 이미지들 표시
            if (node.OutputImages != null && node.OutputImages.Count > 0)
            {
                using (Font font = new Font("Segoe UI", 8, FontStyle.Bold))
                using (SolidBrush textBrush = new SolidBrush(Color.Orange))
                {
                    g.DrawString("OUTPUT", font, textBrush, nodeRect.X + 10, imageY - 15);
                }
                
                int outputImagesPerRow = Math.Min(4, node.OutputImages.Count);
                int outputRowHeight = imageSize + spacing;
                
                for (int i = 0; i < node.OutputImages.Count; i++)
                {
                    int row = i / outputImagesPerRow;
                    int col = i % outputImagesPerRow;
                    
                    int x = nodeRect.X + 10 + col * (imageSize + spacing);
                    int y = imageY + row * outputRowHeight;
                    
                    Rectangle imgRect = new Rectangle(x, y, imageSize, imageSize);
                    
                    if (node.OutputImages[i] != null)
                    {
                        // GIF 애니메이션 시작
                        if (IsAnimatedGif(node.OutputImages[i]))
                        {
                            ImageAnimator.Animate(node.OutputImages[i], OnFrameChanged);
                        }
                        
                        g.DrawImage(node.OutputImages[i], imgRect);
                        
                        string imageName = node.OutputImageNames[i];
                        if (!string.IsNullOrEmpty(imageName))
                        {
                            using (Font nameFont = new Font("Segoe UI", 6))
                            using (SolidBrush nameBrush = new SolidBrush(Color.White))
                            {
                                g.DrawString(Path.GetFileNameWithoutExtension(imageName), 
                                           nameFont, nameBrush, x, y + imageSize + 2);
                            }
                        }
                    }
                    else
                    {
                        g.FillRectangle(Brushes.DarkGray, imgRect);
                        g.DrawRectangle(Pens.Gray, imgRect);
                    }
                }
            }
        }
        
        private void DrawNodePorts(Graphics g, Node node, Rectangle nodeRect)
        {
            int portY = nodeRect.Bottom - 30;
            
            foreach (var port in node.InputPorts)
            {
                DrawPort(g, port, new Point(nodeRect.X - 8, portY));
                
                using (Font font = new Font("Segoe UI", 9))
                using (SolidBrush textBrush = new SolidBrush(Color.LightGray))
                {
                    g.DrawString(port.Name, font, textBrush, nodeRect.X + 15, portY - 8);
                }
            }
            
            foreach (var port in node.OutputPorts)
            {
                DrawPort(g, port, new Point(nodeRect.Right - 8, portY));
                
                using (Font font = new Font("Segoe UI", 9))
                using (SolidBrush textBrush = new SolidBrush(Color.LightGray))
                {
                    SizeF textSize = g.MeasureString(port.Name, font);
                    g.DrawString(port.Name, font, textBrush, 
                               nodeRect.Right - textSize.Width - 15, portY - 8);
                }
            }
        }
        
        private int GetNodeWidth(Node node)
        {
            int maxImages = Math.Max(node.InputImages.Count, node.OutputImages.Count);
            int imagesPerRow = Math.Min(4, maxImages);
            return Math.Max(200, 20 + imagesPerRow * 65);
        }
        
        private int GetNodeHeight(Node node)
        {
            int inputRows = node.InputImages != null ? (node.InputImages.Count - 1) / 4 + 1 : 0;
            int outputRows = node.OutputImages != null ? (node.OutputImages.Count - 1) / 4 + 1 : 0;
            
            int baseHeight = 80;
            int imageHeight = (inputRows + outputRows) * 80;
            
            if (inputRows > 0) imageHeight += 20;
            if (outputRows > 0) imageHeight += 20;
            
            return Math.Max(baseHeight, baseHeight + imageHeight);
        }
        
        private Color GetNodeColor(NodeType type)
        {
            switch (type)
            {
                case NodeType.Original: return Color.FromArgb(70, 130, 180);
                case NodeType.Step01: return Color.FromArgb(220, 20, 60);
                case NodeType.Step02: return Color.FromArgb(255, 140, 0);
                case NodeType.Step03: return Color.FromArgb(50, 205, 50);
                case NodeType.Step04: return Color.FromArgb(138, 43, 226);
                case NodeType.Step05: return Color.FromArgb(255, 20, 147);
                default: return Color.FromArgb(70, 70, 74);
            }
        }
        
        private void DrawPort(Graphics g, NodePort port, Point position)
        {
            Rectangle portRect = new Rectangle(position.X - 8, position.Y - 8, 16, 16);
            port.Bounds = portRect;
            
            Color portColor = port.Type == PortType.Input ? Color.LightBlue : Color.Orange;
            
            using (SolidBrush brush = new SolidBrush(portColor))
            {
                g.FillEllipse(brush, portRect);
            }
            
            using (Pen pen = new Pen(Color.White, 2))
            {
                g.DrawEllipse(pen, portRect);
            }
        }
        
        private void DrawConnection(Graphics g, Connection connection)
        {
            Point startPos = GetPortCenter(connection.OutputPort);
            Point endPos = GetPortCenter(connection.InputPort);
            
            bool isHighlighted = IsConnectionNearMouse(connection, lastMousePos);
            Color connectionColor = isHighlighted ? Color.Red : Color.Yellow;
            int lineWidth = isHighlighted ? 4 : 3;
            
            DrawBezierConnection(g, startPos, endPos, connectionColor, lineWidth);
        }
        
        private void DrawTempConnection(Graphics g, NodePort startPort, Point mousePos)
        {
            Point startPos = GetPortCenter(startPort);
            Point endPos = new Point(
                (int)((mousePos.X - canvasOffset.X) / zoomLevel),
                (int)((mousePos.Y - canvasOffset.Y) / zoomLevel)
            );
            
            DrawBezierConnection(g, startPos, endPos, Color.Gray, 2);
        }
        
        private void DrawBezierConnection(Graphics g, Point start, Point end, Color color, int lineWidth = 3)
        {
            using (Pen pen = new Pen(color, lineWidth))
            {
                int controlOffset = Math.Abs(end.X - start.X) / 2;
                Point control1 = new Point(start.X + controlOffset, start.Y);
                Point control2 = new Point(end.X - controlOffset, end.Y);
                
                g.DrawBezier(pen, start, control1, control2, end);
            }
        }
        
        private Point GetPortCenter(NodePort port)
        {
            return new Point(
                port.Bounds.X + port.Bounds.Width / 2,
                port.Bounds.Y + port.Bounds.Height / 2
            );
        }
        
        private Node GetNodeAtPosition(Point position)
        {
            Point adjustedPos = new Point(
                (int)((position.X - canvasOffset.X) / zoomLevel),
                (int)((position.Y - canvasOffset.Y) / zoomLevel)
            );
            
            for (int i = nodes.Count - 1; i >= 0; i--)
            {
                int nodeWidth = GetNodeWidth(nodes[i]);
                int nodeHeight = GetNodeHeight(nodes[i]);
                Rectangle nodeRect = new Rectangle(nodes[i].Position.X, nodes[i].Position.Y, nodeWidth, nodeHeight);
                if (nodeRect.Contains(adjustedPos))
                {
                    return nodes[i];
                }
            }
            return null;
        }
        
        private NodePort GetPortAtPosition(Point position)
        {
            Point adjustedPos = new Point(
                (int)((position.X - canvasOffset.X) / zoomLevel),
                (int)((position.Y - canvasOffset.Y) / zoomLevel)
            );
            
            foreach (var node in nodes)
            {
                foreach (var port in node.InputPorts.Concat(node.OutputPorts))
                {
                    if (port.Bounds.Contains(adjustedPos))
                    {
                        return port;
                    }
                }
            }
            return null;
        }
        
        private Connection GetConnectionAtPosition(Point position)
        {
            Point adjustedPos = new Point(
                (int)((position.X - canvasOffset.X) / zoomLevel),
                (int)((position.Y - canvasOffset.Y) / zoomLevel)
            );
            
            foreach (var connection in connections)
            {
                if (IsPointOnConnection(connection, adjustedPos))
                {
                    return connection;
                }
            }
            return null;
        }
        
        private bool IsPointOnConnection(Connection connection, Point point)
        {
            Point startPos = GetPortCenter(connection.OutputPort);
            Point endPos = GetPortCenter(connection.InputPort);
            
            int controlOffset = Math.Abs(endPos.X - startPos.X) / 2;
            Point control1 = new Point(startPos.X + controlOffset, startPos.Y);
            Point control2 = new Point(endPos.X - controlOffset, endPos.Y);
            
            const int segments = 20;
            const double threshold = 10.0;
            
            for (int i = 0; i <= segments; i++)
            {
                double t = (double)i / segments;
                Point bezierPoint = CalculateBezierPoint(startPos, control1, control2, endPos, t);
                
                double distance = Math.Sqrt(Math.Pow(point.X - bezierPoint.X, 2) + Math.Pow(point.Y - bezierPoint.Y, 2));
                if (distance <= threshold)
                {
                    return true;
                }
            }
            
            return false;
        }
        
        private bool IsConnectionNearMouse(Connection connection, Point mousePos)
        {
            Point adjustedPos = new Point(
                (int)((mousePos.X - canvasOffset.X) / zoomLevel),
                (int)((mousePos.Y - canvasOffset.Y) / zoomLevel)
            );
            
            return IsPointOnConnection(connection, adjustedPos);
        }
        
        private Point CalculateBezierPoint(Point p0, Point p1, Point p2, Point p3, double t)
        {
            double u = 1 - t;
            double tt = t * t;
            double uu = u * u;
            double uuu = uu * u;
            double ttt = tt * t;
            
            double x = uuu * p0.X + 3 * uu * t * p1.X + 3 * u * tt * p2.X + ttt * p3.X;
            double y = uuu * p0.Y + 3 * uu * t * p1.Y + 3 * u * tt * p2.Y + ttt * p3.Y;
            
            return new Point((int)x, (int)y);
        }
        
        private bool CanConnect(NodePort port1, NodePort port2)
        {
            return port1.Type != port2.Type && 
                   !connections.Any(c => (c.OutputPort == port1 && c.InputPort == port2) ||
                                        (c.OutputPort == port2 && c.InputPort == port1));
        }
        
        private void ProcessImageFlow(NodePort outputPort, NodePort inputPort)
        {
            NodePort fromPort = outputPort.Type == PortType.Output ? outputPort : inputPort;
            NodePort toPort = outputPort.Type == PortType.Input ? outputPort : inputPort;
            
            Node fromNode = fromPort.ParentNode;
            Node toNode = toPort.ParentNode;
            
            ProcessSpecificNodeConnection(fromNode, toNode);
            this.Invalidate();
        }
        
        private void ProcessSpecificNodeConnection(Node fromNode, Node toNode)
        {
            switch (toNode.Type)
            {
                case NodeType.Step01:
                    if (fromNode.Type == NodeType.Original)
                    {
                        toNode.SetInputImages(fromNode.OutputImages, fromNode.OutputImageNames);
                        toNode.LoadImages(new string[] 
                        {
                            "images/debug_full_mask.png",
                            "images/background.png", 
                            "images/output_no_bg.png"
                        }, false);
                    }
                    break;
                    
                case NodeType.Step02:
                    if (fromNode.Type == NodeType.Step01)
                    {
                        var selectedImages = new List<Image>();
                        var selectedNames = new List<string>();
                        
                        if (fromNode.OutputImages.Count >= 2)
                        {
                            selectedImages.Add(fromNode.OutputImages[0]);
                            selectedImages.Add(fromNode.OutputImages[1]);
                            selectedNames.Add("images/debug_full_mask.png");
                            selectedNames.Add("images/background.png");
                        }
                        
                        toNode.SetInputImages(selectedImages, selectedNames);
                        toNode.LoadImages(new string[] { "images/lama_output.png" }, false);
                    }
                    break;
                    
                case NodeType.Step03:
                    if (fromNode.Type == NodeType.Original)
                    {
                        var combinedImages = new List<Image>(fromNode.OutputImages);
                        var combinedNames = new List<string>(fromNode.OutputImageNames ?? new List<string>());
                        
                        // emoji_rabbit.png 이미지 로드
                        Image emojiImage;
                        string emojiPath = "images/emoji_rabbit.png";
                        
                        try
                        {
                            if (File.Exists(emojiPath))
                            {
                                emojiImage = Image.FromFile(emojiPath);
                            }
                            else
                            {
                                // 상대 경로로도 시도
                                string relativePath = Path.Combine(Application.StartupPath, emojiPath);
                                if (File.Exists(relativePath))
                                {
                                    emojiImage = Image.FromFile(relativePath);
                                }
                                else
                                {
                                    // 파일이 없으면 플레이스홀더 생성
                                    emojiImage = CreatePlaceholderImage("emoji_rabbit.png", Color.Yellow);
                                }
                            }
                        }
                        catch (Exception)
                        {
                            // 오류 발생 시 플레이스홀더 생성
                            emojiImage = CreatePlaceholderImage("emoji_rabbit.png", Color.Yellow);
                        }
                        
                        combinedImages.Add(emojiImage);
                        combinedNames.Add("emoji_rabbit.png");
                        
                        toNode.SetInputImages(combinedImages, combinedNames);
                        toNode.LoadImages(new string[] { "images/output.png" }, false);
                    }
                    break;
                    
                case NodeType.Step04:
                    if (fromNode.Type == NodeType.Step01)
                    {
                        var selectedImages = new List<Image>();
                        var selectedNames = new List<string>();
                        
                        if (fromNode.OutputImages.Count >= 3)
                        {
                            selectedImages.Add(fromNode.OutputImages[2]);
                            selectedNames.Add("images/output_no_bg.png");
                        }
                        
                        toNode.SetInputImages(selectedImages, selectedNames);
                        
                        string[] step04Outputs = new string[]
                        {
                            "images/360_view_001_000deg_from_000deg.png",
                            "images/360_view_002_045deg_from_060deg.png",
                            "images/360_view_003_090deg_from_090deg.png",
                            "images/360_view_004_135deg_from_090deg.png",
                            "images/360_view_005_180deg_from_180deg.png",
                            "images/360_view_006_225deg_from_240deg.png",
                            "images/360_view_007_270deg_from_270deg.png",
                            "images/360_view_008_315deg_from_000deg.png",
                            "images/ultrafast_360.gif"
                        };
                        
                        toNode.LoadImages(step04Outputs, false);
                    }
                    break;
                    
                case NodeType.Step05:
                    if (fromNode.Type == NodeType.Step04)
                    {
                        var selectedImages = new List<Image>();
                        var selectedNames = new List<string>();
                        
                        if (fromNode.OutputImages.Count >= 8)
                        {
                            for (int i = 0; i < 8; i++)
                            {
                                selectedImages.Add(fromNode.OutputImages[i]);
                                selectedNames.Add(fromNode.OutputImageNames[i]);
                            }
                        }
                        
                        toNode.SetInputImages(selectedImages, selectedNames);
                        toNode.LoadImages(new string[] { "images/step05_sc_2025-08-11.gif" }, false);
                    }
                    break;
            }
        }
        
        private Image CreatePlaceholderImage(string fileName, Color backgroundColor)
        {
            Bitmap image = new Bitmap(100, 80);
            using (Graphics g = Graphics.FromImage(image))
            {
                g.FillRectangle(new SolidBrush(backgroundColor), 0, 0, 100, 80);
                
                using (Font font = new Font("Arial", 8, FontStyle.Bold))
                {
                    string displayName = Path.GetFileNameWithoutExtension(fileName);
                    if (displayName.Length > 12)
                        displayName = displayName.Substring(0, 12) + "...";
                        
                    SizeF textSize = g.MeasureString(displayName, font);
                    g.DrawString(displayName, font, Brushes.Black,
                               (100 - textSize.Width) / 2, (80 - textSize.Height) / 2);
                }
                
                g.DrawRectangle(Pens.Black, 0, 0, 99, 79);
            }
            return image;
        }
        
        private void RemoveConnection(Connection connection)
        {
            if (connections.Contains(connection))
            {
                connections.Remove(connection);
                ResetNodeAfterDisconnection(connection.InputPort.ParentNode);
                UpdateStatusMessage("연결이 제거되었습니다: " + connection.OutputPort.ParentNode.Title + "→" + connection.InputPort.ParentNode.Title);
            }
        }
        
        private void UpdateStatusMessage(string message)
        {
            Control parent = this.Parent;
            while (parent != null && !(parent is Form))
            {
                parent = parent.Parent;
            }
            
            Form parentForm = parent as Form;
            if (parentForm != null)
            {
                var statusStrip = parentForm.Controls.OfType<StatusStrip>().FirstOrDefault();
                if (statusStrip != null)
                {
                    var statusLabel = statusStrip.Items.OfType<ToolStripStatusLabel>().FirstOrDefault();
                    if (statusLabel != null)
                    {
                        statusLabel.Text = message;
                    }
                }
            }
        }
        
        private void ResetNodeAfterDisconnection(Node node)
        {
            node.InputImages.Clear();
            node.InputImageNames.Clear();
            
            bool hasOutputConnection = connections.Any(c => c.OutputPort.ParentNode == node);
            if (!hasOutputConnection && node.Type != NodeType.Original)
            {
                node.OutputImages.Clear();
                node.OutputImageNames.Clear();
            }
        }
        
        public void ClearAllConnections()
        {
            connections.Clear();
            
            foreach (var node in nodes)
            {
                if (node.Type != NodeType.Original)
                {
                    node.InputImages.Clear();
                    node.InputImageNames.Clear();
                    node.OutputImages.Clear();
                    node.OutputImageNames.Clear();
                }
            }
            
            this.Invalidate();
        }
        
        public void ResetAllNodes()
        {
            connections.Clear();
            
            foreach (var node in nodes)
            {
                node.InputImages.Clear();
                node.InputImageNames.Clear();
                node.OutputImages.Clear();
                node.OutputImageNames.Clear();
                
                if (node.Type == NodeType.Original)
                {
                    node.LoadImages(new string[] { "input.png" }, false);
                }
            }
            
            this.Invalidate();
        }
        private void OnFrameChanged(object sender, EventArgs e)
        {
            // GIF 프레임이 변경될 때 호출되는 콜백
            this.Invalidate();
        }
        
        private bool IsAnimatedGif(Image image)
        {
            if (image == null) return false;
            
            // GIF 형식이고 프레임이 2개 이상인지 확인
            if (image.RawFormat.Equals(ImageFormat.Gif))
            {
                var dimension = new FrameDimension(image.FrameDimensionsList[0]);
                return image.GetFrameCount(dimension) > 1;
            }
            
            return false;
        }
    }
    
    public class Node
    {
        public string Title { get; set; }
        public Point Position { get; set; }
        public List<NodePort> InputPorts { get; set; }
        public List<NodePort> OutputPorts { get; set; }
        public List<Image> InputImages { get; set; }
        public List<Image> OutputImages { get; set; }
        public List<string> InputImageNames { get; set; }
        public List<string> OutputImageNames { get; set; }
        public NodeType Type { get; set; }
        
        public Node(string title, Point position, NodeType type)
        {
            Title = title;
            Position = position;
            Type = type;
            InputPorts = new List<NodePort>();
            OutputPorts = new List<NodePort>();
            InputImages = new List<Image>();
            OutputImages = new List<Image>();
            InputImageNames = new List<string>();
            OutputImageNames = new List<string>();
        }
        
        public void LoadImages(string[] imageFileNames, bool isInput = true)
        {
            var images = isInput ? InputImages : OutputImages;
            var imageNames = isInput ? InputImageNames : OutputImageNames;
            
            images.Clear();
            imageNames.Clear();
            
            foreach (string fileName in imageFileNames)
            {
                try
                {
                    Image image;
                    if (File.Exists(fileName))
                    {
                        image = Image.FromFile(fileName);
                    }
                    else
                    {
                        Color placeholderColor = GetPlaceholderColor(fileName);
                        image = CreatePlaceholderImage(fileName, placeholderColor);
                    }
                    
                    images.Add(image);
                    imageNames.Add(fileName);
                }
                catch (Exception)
                {
                    Image errorImage = CreatePlaceholderImage("ERROR: " + fileName, Color.Red);
                    images.Add(errorImage);
                    imageNames.Add(fileName);
                }
            }
        }
        
        public void SetInputImages(List<Image> images, List<string> imageNames)
        {
            InputImages.Clear();
            InputImageNames.Clear();
            
            if (images != null)
            {
                InputImages.AddRange(images);
            }
            
            if (imageNames != null)
            {
                InputImageNames.AddRange(imageNames);
            }
        }
        
        private Color GetPlaceholderColor(string fileName)
        {
            string lowerFileName = fileName.ToLower();
            
            if (lowerFileName.Contains("input")) return Color.LightBlue;
            if (lowerFileName.Contains("mask")) return Color.Purple;
            if (lowerFileName.Contains("background")) return Color.Green;
            if (lowerFileName.Contains("output")) return Color.Orange;
            if (lowerFileName.Contains("lama")) return Color.Cyan;
            if (lowerFileName.Contains("emoji")) return Color.Yellow;
            if (lowerFileName.Contains("360")) return Color.Pink;
            if (lowerFileName.Contains("gif")) return Color.Magenta;
            if (lowerFileName.Contains("step05")) return Color.LimeGreen;
            
            return Color.Gray;
        }
        
        private Image CreatePlaceholderImage(string fileName, Color backgroundColor)
        {
            Bitmap image = new Bitmap(100, 80);
            using (Graphics g = Graphics.FromImage(image))
            {
                g.FillRectangle(new SolidBrush(backgroundColor), 0, 0, 100, 80);
                
                using (Font font = new Font("Arial", 7, FontStyle.Bold))
                {
                    string displayName = Path.GetFileNameWithoutExtension(fileName);
                    if (displayName.Length > 15)
                        displayName = displayName.Substring(0, 15) + "...";
                        
                    SizeF textSize = g.MeasureString(displayName, font);
                    float x = Math.Max(2, (100 - textSize.Width) / 2);
                    float y = Math.Max(2, (80 - textSize.Height) / 2);
                    
                    g.DrawString(displayName, font, Brushes.Black, x, y);
                }
                
                g.DrawRectangle(Pens.Black, 0, 0, 99, 79);
            }
            return image;
        }
    }
    
    public enum NodeType
    {
        Original,
        Step01,
        Step02,
        Step03,
        Step04,
        Step05
    }
    
    public class NodePort
    {
        public string Name { get; set; }
        public PortType Type { get; set; }
        public Node ParentNode { get; set; }
        public Rectangle Bounds { get; set; }
        
        public NodePort(string name, PortType type, Node parentNode)
        {
            Name = name;
            Type = type;
            ParentNode = parentNode;
        }
    }
    
    public enum PortType
    {
        Input,
        Output
    }
    
    public class Connection
    {
        public NodePort OutputPort { get; set; }
        public NodePort InputPort { get; set; }
        
        public Connection(NodePort outputPort, NodePort inputPort)
        {
            if (outputPort.Type == PortType.Output && inputPort.Type == PortType.Input)
            {
                OutputPort = outputPort;
                InputPort = inputPort;
            }
            else
            {
                OutputPort = inputPort.Type == PortType.Output ? inputPort : outputPort;
                InputPort = inputPort.Type == PortType.Input ? inputPort : outputPort;
            }
        }
    }
    
    public static class GraphicsExtensions
    {
        public static void FillRoundedRectangle(this Graphics g, Brush brush, Rectangle rect, int radius)
        {
            using (GraphicsPath path = CreateRoundedRectanglePath(rect, radius))
            {
                g.FillPath(brush, path);
            }
        }
        
        public static void DrawRoundedRectangle(this Graphics g, Pen pen, Rectangle rect, int radius)
        {
            using (GraphicsPath path = CreateRoundedRectanglePath(rect, radius))
            {
                g.DrawPath(pen, path);
            }
        }
        
        private static GraphicsPath CreateRoundedRectanglePath(Rectangle rect, int radius)
        {
            GraphicsPath path = new GraphicsPath();
            path.StartFigure();
            path.AddArc(rect.X, rect.Y, radius, radius, 180, 90);
            path.AddArc(rect.Right - radius, rect.Y, radius, radius, 270, 90);
            path.AddArc(rect.Right - radius, rect.Bottom - radius, radius, radius, 0, 90);
            path.AddArc(rect.X, rect.Bottom - radius, radius, radius, 90, 90);
            path.CloseFigure();
            return path;
        }
    }
    
	/// <summary>
	/// Description of MainForm.
	/// </summary>
	public partial class MainForm : Form
	{
        private NodeCanvas canvas;
        private MenuStrip menuStrip;
        		
		public MainForm()
		{
			//
			// The InitializeComponent() call is required for Windows Forms designer support.
			//
			InitializeComponent();
			
			//
			// TODO: Add constructor code after the InitializeComponent() call.
			//
            this.Text = "이미지 처리 워크플로우 - Node Based UI";
            this.Size = new Size(1400, 900);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.WindowState = FormWindowState.Maximized;
            
            CreateMenuStrip();
            
            canvas = new NodeCanvas();
            canvas.Dock = DockStyle.Fill;
            this.Controls.Add(canvas);
            
            CreateStatusBar();
			
		}
		
        private void CreateMenuStrip()
        {
            menuStrip = new MenuStrip();
            
            // 파일 메뉴
            ToolStripMenuItem fileMenu = new ToolStripMenuItem("파일");
            
            ToolStripMenuItem loadImageItem = new ToolStripMenuItem("원본 이미지 로드");
            loadImageItem.Click += LoadImageItem_Click;
            
            ToolStripMenuItem saveAllItem = new ToolStripMenuItem("모든 결과 저장");
            saveAllItem.Click += SaveAllItem_Click;
            
            ToolStripMenuItem exitItem = new ToolStripMenuItem("종료");
            exitItem.Click += (s, e) => this.Close();
            
            fileMenu.DropDownItems.Add(loadImageItem);
            fileMenu.DropDownItems.Add(new ToolStripSeparator());
            fileMenu.DropDownItems.Add(saveAllItem);
            fileMenu.DropDownItems.Add(new ToolStripSeparator());
            fileMenu.DropDownItems.Add(exitItem);
            
            // 편집 메뉴
            ToolStripMenuItem editMenu = new ToolStripMenuItem("편집");
            
            ToolStripMenuItem clearAllConnectionsItem = new ToolStripMenuItem("모든 연결 제거");
            clearAllConnectionsItem.Click += ClearAllConnectionsItem_Click;
            
            ToolStripMenuItem resetAllNodesItem = new ToolStripMenuItem("모든 노드 리셋");
            resetAllNodesItem.Click += ResetAllNodesItem_Click;
            
            editMenu.DropDownItems.Add(clearAllConnectionsItem);
            editMenu.DropDownItems.Add(resetAllNodesItem);
            
            // 보기 메뉴
            ToolStripMenuItem viewMenu = new ToolStripMenuItem("보기");
            
            ToolStripMenuItem resetViewItem = new ToolStripMenuItem("뷰 리셋");
            resetViewItem.Click += (s, e) => {
                canvas.Invalidate();
            };
            
            ToolStripMenuItem fitToScreenItem = new ToolStripMenuItem("화면에 맞춤");
            fitToScreenItem.Click += (s, e) => {
                canvas.Invalidate();
            };
            
            viewMenu.DropDownItems.Add(resetViewItem);
            viewMenu.DropDownItems.Add(fitToScreenItem);
            
            // 도움말 메뉴
            ToolStripMenuItem helpMenu = new ToolStripMenuItem("도움말");
            
            ToolStripMenuItem aboutItem = new ToolStripMenuItem("정보");
            aboutItem.Click += (s, e) => {
                MessageBox.Show(
                    "이미지 처리 워크플로우 시스템\n\n" +
                    "사용법:\n" +
                    "1. 노드를 드래그하여 이동\n" +
                    "2. 출력 포트에서 입력 포트로 연결\n" +
                    "3. 연결선을 우클릭하여 제거\n" +
                    "4. 마우스 휠로 확대/축소\n" +
                    "5. 가운데 버튼으로 캔버스 이동\n\n" +
                    "각 단계별로 이미지가 자동 처리됩니다.",
                    "정보", MessageBoxButtons.OK, MessageBoxIcon.Information);
            };
            
            helpMenu.DropDownItems.Add(aboutItem);
            
            menuStrip.Items.Add(fileMenu);
            menuStrip.Items.Add(editMenu);
            menuStrip.Items.Add(viewMenu);
            menuStrip.Items.Add(helpMenu);
            
            this.MainMenuStrip = menuStrip;
            this.Controls.Add(menuStrip);
        }

        private void CreateStatusBar()
        {
            StatusStrip statusStrip = new StatusStrip();
            
            ToolStripStatusLabel statusLabel = new ToolStripStatusLabel();
            statusLabel.Text = "준비됨 - 노드를 연결하여 이미지 처리 워크플로우를 시작하세요";
            statusLabel.Spring = true;
            statusLabel.TextAlign = ContentAlignment.MiddleLeft;
            
            ToolStripStatusLabel nodeCountLabel = new ToolStripStatusLabel();
            nodeCountLabel.Text = "노드: " + canvas.Nodes.Count + "개";
            
            statusStrip.Items.Add(statusLabel);
            statusStrip.Items.Add(nodeCountLabel);
            
            this.Controls.Add(statusStrip);
        }

        private void LoadImageItem_Click(object sender, EventArgs e)
        {
            using (OpenFileDialog dialog = new OpenFileDialog())
            {
                dialog.Filter = "이미지 파일|*.jpg;*.jpeg;*.png;*.bmp;*.gif|모든 파일|*.*";
                dialog.Title = "원본 이미지 선택";
                
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        var originalNode = canvas.Nodes.FirstOrDefault(n => n.Type == NodeType.Original);
                        if (originalNode != null)
                        {
                            originalNode.OutputImages.Clear();
                            originalNode.OutputImageNames.Clear();
                            
                            Image loadedImage = Image.FromFile(dialog.FileName);
                            originalNode.OutputImages.Add(loadedImage);
                            originalNode.OutputImageNames.Add(Path.GetFileName(dialog.FileName));
                            
                            canvas.Invalidate();
                            
                            MessageBox.Show("이미지가 로드되었습니다: " + Path.GetFileName(dialog.FileName), 
                                          "로드 완료", MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show("이미지 로드 중 오류가 발생했습니다:\n" + ex.Message, 
                                      "오류", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void SaveAllItem_Click(object sender, EventArgs e)
        {
            using (FolderBrowserDialog dialog = new FolderBrowserDialog())
            {
                dialog.Description = "결과 이미지들을 저장할 폴더를 선택하세요";
                
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        int savedCount = 0;
                        
                        foreach (var node in canvas.Nodes)
                        {
                            if (node.OutputImages != null && node.OutputImages.Count > 0)
                            {
                                for (int i = 0; i < node.OutputImages.Count; i++)
                                {
                                    if (node.OutputImages[i] != null)
                                    {
                                        string fileName = node.OutputImageNames != null && i < node.OutputImageNames.Count 
                                            ? node.OutputImageNames[i] 
                                            : node.Title + "_output_" + i + ".png";
                                            
                                        string fullPath = Path.Combine(dialog.SelectedPath, node.Title + "_" + fileName);
                                        
                                        if (fileName.EndsWith(".gif"))
                                        {
                                            node.OutputImages[i].Save(fullPath, ImageFormat.Gif);
                                        }
                                        else
                                        {
                                            node.OutputImages[i].Save(fullPath, ImageFormat.Png);
                                        }
                                        
                                        savedCount++;
                                    }
                                }
                            }
                        }
                        
                        MessageBox.Show(savedCount + "개의 이미지가 저장되었습니다.\n저장 위치: " + dialog.SelectedPath, 
                                      "저장 완료", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show("이미지 저장 중 오류가 발생했습니다:\n" + ex.Message , 
                                      "오류", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void ClearAllConnectionsItem_Click(object sender, EventArgs e)
        {
            if (MessageBox.Show("모든 연결을 제거하시겠습니까?", "확인", 
                              MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
            {
                canvas.ClearAllConnections();
                
                var statusStrip = this.Controls.OfType<StatusStrip>().FirstOrDefault();
                if (statusStrip != null)
                {
                    var statusLabel = statusStrip.Items.OfType<ToolStripStatusLabel>().FirstOrDefault();
                    if (statusLabel != null)
                    {
                        statusLabel.Text = "모든 연결이 제거되었습니다";
                    }
                }
            }
        }

        private void ResetAllNodesItem_Click(object sender, EventArgs e)
        {
            if (MessageBox.Show("모든 노드를 초기 상태로 리셋하시겠습니까?", "확인", 
                              MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
            {
                canvas.ResetAllNodes();
                
                var statusStrip = this.Controls.OfType<StatusStrip>().FirstOrDefault();
                if (statusStrip != null)
                {
                    var statusLabel = statusStrip.Items.OfType<ToolStripStatusLabel>().FirstOrDefault();
                    if (statusLabel != null)
                    {
                        statusLabel.Text = "모든 노드가 리셋되었습니다";
                    }
                }
            }
        }        
		
	}
}
