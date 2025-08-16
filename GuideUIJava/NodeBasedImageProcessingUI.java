import javax.swing.*;
import javax.swing.filechooser.FileNameExtensionFilter;
import javax.swing.Timer;

import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.*;
import java.util.List;
import javax.imageio.ImageIO;

public class NodeBasedImageProcessingUI extends JFrame {
    private NodeCanvas canvas;
    private JMenuBar menuBar;
    private JLabel statusLabel;
    
    public NodeBasedImageProcessingUI() {
        initializeComponents();
    }
    
    private void initializeComponents() {
        setTitle("이미지 처리 워크플로우 - Node Based UI (Java)");
        setSize(1400, 900);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        setExtendedState(JFrame.MAXIMIZED_BOTH);
        
        createMenuBar();
        
        canvas = new NodeCanvas();
        add(canvas, BorderLayout.CENTER);
        
        createStatusBar();
    }
    
    private void createMenuBar() {
        menuBar = new JMenuBar();
        
        // 파일 메뉴
        JMenu fileMenu = new JMenu("파일");
        
        JMenuItem loadImageItem = new JMenuItem("원본 이미지 로드");
        loadImageItem.addActionListener(this::loadImageAction);
        
        JMenuItem saveAllItem = new JMenuItem("모든 결과 저장");
        saveAllItem.addActionListener(this::saveAllAction);
        
        JMenuItem exitItem = new JMenuItem("종료");
        exitItem.addActionListener(e -> System.exit(0));
        
        fileMenu.add(loadImageItem);
        fileMenu.addSeparator();
        fileMenu.add(saveAllItem);
        fileMenu.addSeparator();
        fileMenu.add(exitItem);
        
        // 편집 메뉴
        JMenu editMenu = new JMenu("편집");
        
        JMenuItem clearConnectionsItem = new JMenuItem("모든 연결 제거");
        clearConnectionsItem.addActionListener(this::clearConnectionsAction);
        
        JMenuItem resetNodesItem = new JMenuItem("모든 노드 리셋");
        resetNodesItem.addActionListener(this::resetNodesAction);
        
        editMenu.add(clearConnectionsItem);
        editMenu.add(resetNodesItem);
        
        // 보기 메뉴
        JMenu viewMenu = new JMenu("보기");
        
        JMenuItem resetViewItem = new JMenuItem("뷰 리셋");
        resetViewItem.addActionListener(e -> canvas.repaint());
        
        viewMenu.add(resetViewItem);
        
        // 도움말 메뉴
        JMenu helpMenu = new JMenu("도움말");
        
        JMenuItem aboutItem = new JMenuItem("정보");
        aboutItem.addActionListener(this::aboutAction);
        
        helpMenu.add(aboutItem);
        
        menuBar.add(fileMenu);
        menuBar.add(editMenu);
        menuBar.add(viewMenu);
        menuBar.add(helpMenu);
        
        setJMenuBar(menuBar);
    }
    
    private void createStatusBar() {
        JPanel statusPanel = new JPanel(new BorderLayout());
        statusLabel = new JLabel("준비됨 - 노드를 연결하여 이미지 처리 워크플로우를 시작하세요");
        statusLabel.setBorder(BorderFactory.createLoweredBevelBorder());
        statusPanel.add(statusLabel, BorderLayout.CENTER);
        
        JLabel nodeCountLabel = new JLabel("노드: " + canvas.getNodes().size() + "개");
        nodeCountLabel.setBorder(BorderFactory.createLoweredBevelBorder());
        statusPanel.add(nodeCountLabel, BorderLayout.EAST);
        
        add(statusPanel, BorderLayout.SOUTH);
    }
    
    private void loadImageAction(ActionEvent e) {
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setFileFilter(new FileNameExtensionFilter("이미지 파일", "jpg", "jpeg", "png", "bmp", "gif"));
        fileChooser.setDialogTitle("원본 이미지 선택");
        
        if (fileChooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
            try {
                File selectedFile = fileChooser.getSelectedFile();
                Node originalNode = canvas.getNodes().stream()
                    .filter(n -> n.getType() == NodeType.ORIGINAL)
                    .findFirst().orElse(null);
                    
                if (originalNode != null) {
                    originalNode.getOutputImages().clear();
                    originalNode.getOutputImageNames().clear();
                    
                    BufferedImage loadedImage = ImageIO.read(selectedFile);
                    originalNode.getOutputImages().add(loadedImage);
                    originalNode.getOutputImageNames().add(selectedFile.getName());
                    
                    canvas.repaint();
                    
                    JOptionPane.showMessageDialog(this, 
                        "이미지가 로드되었습니다: " + selectedFile.getName(),
                        "로드 완료", JOptionPane.INFORMATION_MESSAGE);
                }
            } catch (IOException ex) {
                JOptionPane.showMessageDialog(this,
                    "이미지 로드 중 오류가 발생했습니다:\n" + ex.getMessage(),
                    "오류", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    
    private void saveAllAction(ActionEvent e) {
        JFileChooser folderChooser = new JFileChooser();
        folderChooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
        folderChooser.setDialogTitle("결과 이미지들을 저장할 폴더를 선택하세요");
        
        if (folderChooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
            try {
                File selectedFolder = folderChooser.getSelectedFile();
                int savedCount = 0;
                
                for (Node node : canvas.getNodes()) {
                    if (node.getOutputImages() != null && !node.getOutputImages().isEmpty()) {
                        for (int i = 0; i < node.getOutputImages().size(); i++) {
                            BufferedImage image = node.getOutputImages().get(i);
                            if (image != null) {
                                String fileName = i < node.getOutputImageNames().size() 
                                    ? node.getOutputImageNames().get(i)
                                    : node.getTitle() + "_output_" + i + ".png";
                                    
                                File outputFile = new File(selectedFolder, node.getTitle() + "_" + fileName);
                                
                                String format = fileName.toLowerCase().endsWith(".gif") ? "gif" : "png";
                                ImageIO.write(image, format, outputFile);
                                savedCount++;
                            }
                        }
                    }
                }
                
                JOptionPane.showMessageDialog(this,
                    savedCount + "개의 이미지가 저장되었습니다.\n저장 위치: " + selectedFolder.getAbsolutePath(),
                    "저장 완료", JOptionPane.INFORMATION_MESSAGE);
            } catch (IOException ex) {
                JOptionPane.showMessageDialog(this,
                    "이미지 저장 중 오류가 발생했습니다:\n" + ex.getMessage(),
                    "오류", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    
    private void clearConnectionsAction(ActionEvent e) {
        int result = JOptionPane.showConfirmDialog(this,
            "모든 연결을 제거하시겠습니까?", "확인",
            JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE);
            
        if (result == JOptionPane.YES_OPTION) {
            canvas.clearAllConnections();
            statusLabel.setText("모든 연결이 제거되었습니다");
        }
    }
    
    private void resetNodesAction(ActionEvent e) {
        int result = JOptionPane.showConfirmDialog(this,
            "모든 노드를 초기 상태로 리셋하시겠습니까?", "확인",
            JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE);
            
        if (result == JOptionPane.YES_OPTION) {
            canvas.resetAllNodes();
            statusLabel.setText("모든 노드가 리셋되었습니다");
        }
    }
    
    private void aboutAction(ActionEvent e) {
        JOptionPane.showMessageDialog(this,
            "이미지 처리 워크플로우 시스템\n\n" +
            "사용법:\n" +
            "1. 노드를 드래그하여 이동\n" +
            "2. 출력 포트에서 입력 포트로 연결\n" +
            "3. 연결선을 우클릭하여 제거\n" +
            "4. 마우스 휠로 확대/축소\n" +
            "5. 가운데 버튼으로 캔버스 이동\n\n" +
            "각 단계별로 이미지가 자동 처리됩니다.",
            "정보", JOptionPane.INFORMATION_MESSAGE);
    }
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            } catch (Exception e) {
                e.printStackTrace();
            }
            
            new NodeBasedImageProcessingUI().setVisible(true);
        });
    }
}

// ================= NodeCanvas 클래스 =================
class NodeCanvas extends JPanel {
    private List<Node> nodes = new ArrayList<>();
    private List<Connection> connections = new ArrayList<>();
    private Node draggedNode = null;
    private NodePort connectionStartPort = null;
    private Point lastMousePos = new Point();
    private Point canvasOffset = new Point();
    private boolean isPanning = false;
    private float zoomLevel = 1.0f;
    private Timer animationTimer;
    private Set<BufferedImage> animatedImages = new HashSet<>();
    
    public NodeCanvas() {
        initializeComponent();
        addProcessingNodes();
        setupAnimationTimer();
    }
    
    public List<Node> getNodes() {
        return nodes;
    }
    
    public List<Connection> getConnections() {
        return connections;
    }
    
    private void initializeComponent() {
        setBackground(new Color(45, 45, 48));
        setPreferredSize(new Dimension(1200, 800));
        
        addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
                nodeCanvasMousePressed(e);
            }
            
            @Override
            public void mouseReleased(MouseEvent e) {
                nodeCanvasMouseReleased(e);
            }
        });
        
        addMouseMotionListener(new MouseMotionAdapter() {
            @Override
            public void mouseDragged(MouseEvent e) {
                nodeCanvasMouseMoved(e);
            }
            
            @Override
            public void mouseMoved(MouseEvent e) {
                lastMousePos = e.getPoint();
                repaint();
            }
        });
        
        addMouseWheelListener(this::nodeCanvasMouseWheel);
    }
    
    private void setupAnimationTimer() {
        animationTimer = new Timer(50, e -> {
            boolean hasAnimatedImages = false;
            
            for (Node node : nodes) {
                if (node.getInputImages() != null) {
                    for (BufferedImage image : node.getInputImages()) {
                        if (image != null && isAnimatedGif(image)) {
                            hasAnimatedImages = true;
                        }
                    }
                }
                
                if (node.getOutputImages() != null) {
                    for (BufferedImage image : node.getOutputImages()) {
                        if (image != null && isAnimatedGif(image)) {
                            hasAnimatedImages = true;
                        }
                    }
                }
            }
            
            if (hasAnimatedImages) {
                repaint();
            }
        });
        animationTimer.start();
    }
    
    private boolean isAnimatedGif(BufferedImage image) {
        // Java에서 GIF 애니메이션 감지는 복잡하므로 단순화
        return false;
    }
    
    private void addProcessingNodes() {
        // 원본 이미지 노드
        Node originalNode = new Node("원본이미지", new Point(50, 30), NodeType.ORIGINAL);
        originalNode.getOutputPorts().add(new NodePort("Output", PortType.OUTPUT, originalNode));
        originalNode.loadImages(new String[]{"images/input.png"}, false);
        nodes.add(originalNode);
        
        // Step01 노드
        Node step01Node = new Node("Step01", new Point(300, 30), NodeType.STEP01);
        step01Node.getInputPorts().add(new NodePort("Input", PortType.INPUT, step01Node));
        step01Node.getOutputPorts().add(new NodePort("Output", PortType.OUTPUT, step01Node));
        nodes.add(step01Node);
        
        // Step02 노드
        Node step02Node = new Node("Step02", new Point(600, 30), NodeType.STEP02);
        step02Node.getInputPorts().add(new NodePort("Input", PortType.INPUT, step02Node));
        step02Node.getOutputPorts().add(new NodePort("Output", PortType.OUTPUT, step02Node));
        nodes.add(step02Node);
        
        // Step03 노드
        Node step03Node = new Node("Step03", new Point(300, 330), NodeType.STEP03);
        step03Node.getInputPorts().add(new NodePort("Input", PortType.INPUT, step03Node));
        step03Node.getOutputPorts().add(new NodePort("Output", PortType.OUTPUT, step03Node));
        nodes.add(step03Node);
        
        // Step04 노드
        Node step04Node = new Node("Step04", new Point(600, 330), NodeType.STEP04);
        step04Node.getInputPorts().add(new NodePort("Input", PortType.INPUT, step04Node));
        step04Node.getOutputPorts().add(new NodePort("Output", PortType.OUTPUT, step04Node));
        nodes.add(step04Node);
        
        // Step05 노드
        Node step05Node = new Node("Step05", new Point(900, 330), NodeType.STEP05);
        step05Node.getInputPorts().add(new NodePort("Input", PortType.INPUT, step05Node));
        step05Node.getOutputPorts().add(new NodePort("Output", PortType.OUTPUT, step05Node));
        nodes.add(step05Node);
    }
    
    private void nodeCanvasMousePressed(MouseEvent e) {
        lastMousePos = e.getPoint();
        
        if (SwingUtilities.isMiddleMouseButton(e)) {
            isPanning = true;
            return;
        }
        
        // 우클릭 시 연결선 제거 확인
        if (SwingUtilities.isRightMouseButton(e)) {
            Connection clickedConnection = getConnectionAtPosition(e.getPoint());
            if (clickedConnection != null) {
                removeConnection(clickedConnection);
                repaint();
                return;
            }
            
            // 연결 생성 취소
            if (connectionStartPort != null) {
                connectionStartPort = null;
                repaint();
                return;
            }
        }
        
        // 포트 클릭 확인
        NodePort clickedPort = getPortAtPosition(e.getPoint());
        if (clickedPort != null && SwingUtilities.isLeftMouseButton(e)) {
            if (connectionStartPort == null) {
                connectionStartPort = clickedPort;
            } else {
                // 연결 생성
                if (canConnect(connectionStartPort, clickedPort)) {
                    connections.add(new Connection(connectionStartPort, clickedPort));
                    processImageFlow(connectionStartPort, clickedPort);
                }
                connectionStartPort = null;
            }
            repaint();
            return;
        }
        
        // 노드 클릭 확인
        if (SwingUtilities.isLeftMouseButton(e)) {
            draggedNode = getNodeAtPosition(e.getPoint());
            if (draggedNode != null) {
                nodes.remove(draggedNode);
                nodes.add(draggedNode);
            }
        }
    }
    
    private void nodeCanvasMouseMoved(MouseEvent e) {
        if (isPanning) {
            canvasOffset.x += e.getX() - lastMousePos.x;
            canvasOffset.y += e.getY() - lastMousePos.y;
            repaint();
        } else if (draggedNode != null) {
            Point newPos = new Point(
                draggedNode.getPosition().x + e.getX() - lastMousePos.x,
                draggedNode.getPosition().y + e.getY() - lastMousePos.y
            );
            draggedNode.setPosition(newPos);
            repaint();
        } else if (connectionStartPort != null) {
            repaint();
        }
        
        lastMousePos = e.getPoint();
    }
    
    private void nodeCanvasMouseReleased(MouseEvent e) {
        draggedNode = null;
        isPanning = false;
    }
    
    private void nodeCanvasMouseWheel(MouseWheelEvent e) {
        float oldZoom = zoomLevel;
        zoomLevel += e.getWheelRotation() < 0 ? 0.1f : -0.1f;
        zoomLevel = Math.max(0.1f, Math.min(3.0f, zoomLevel));
        
        if (oldZoom != zoomLevel) {
            repaint();
        }
    }
    
    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        Graphics2D g2d = (Graphics2D) g.create();
        g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        
        g2d.translate(canvasOffset.x, canvasOffset.y);
        g2d.scale(zoomLevel, zoomLevel);
        
        drawGrid(g2d);
        
        // 연결선 그리기
        for (Connection connection : connections) {
            drawConnection(g2d, connection);
        }
        
        // 임시 연결선 그리기
        if (connectionStartPort != null) {
            drawTempConnection(g2d, connectionStartPort, lastMousePos);
        }
        
        // 노드 그리기
        for (Node node : nodes) {
            drawNode(g2d, node);
        }
        
        g2d.dispose();
    }
    
    private void drawGrid(Graphics2D g2d) {
        g2d.setColor(new Color(60, 60, 63));
        g2d.setStroke(new BasicStroke(1));
        
        int gridSize = 20;
        int startX = -(canvasOffset.x % gridSize);
        int startY = -(canvasOffset.y % gridSize);
        
        for (int x = startX; x < getWidth(); x += gridSize) {
            g2d.drawLine(x, 0, x, getHeight());
        }
        
        for (int y = startY; y < getHeight(); y += gridSize) {
            g2d.drawLine(0, y, getWidth(), y);
        }
    }
    
    private void drawNode(Graphics2D g2d, Node node) {
        int nodeWidth = getNodeWidth(node);
        int nodeHeight = getNodeHeight(node);
        Rectangle nodeRect = new Rectangle(node.getPosition().x, node.getPosition().y, nodeWidth, nodeHeight);
        
        Color nodeColor = getNodeColor(node.getType());
        Color darkerColor = new Color(
            Math.max(0, nodeColor.getRed() - 20),
            Math.max(0, nodeColor.getGreen() - 20),
            Math.max(0, nodeColor.getBlue() - 20)
        );
        
        // 그라디언트 배경
        GradientPaint gradient = new GradientPaint(
            nodeRect.x, nodeRect.y, nodeColor,
            nodeRect.x, nodeRect.y + nodeRect.height, darkerColor
        );
        g2d.setPaint(gradient);
        g2d.fillRoundRect(nodeRect.x, nodeRect.y, nodeRect.width, nodeRect.height, 8, 8);
        
        // 테두리
        g2d.setColor(new Color(150, 150, 154));
        g2d.setStroke(new BasicStroke(2));
        g2d.drawRoundRect(nodeRect.x, nodeRect.y, nodeRect.width, nodeRect.height, 8, 8);
        
        // 제목
        g2d.setColor(Color.WHITE);
        g2d.setFont(new Font("SansSerif", Font.BOLD, 11));
        FontMetrics fm = g2d.getFontMetrics();
        int titleX = nodeRect.x + (nodeRect.width - fm.stringWidth(node.getTitle())) / 2;
        int titleY = nodeRect.y + 20;
        g2d.drawString(node.getTitle(), titleX, titleY);
        
        drawNodeImages(g2d, node, nodeRect);
        drawNodePorts(g2d, node, nodeRect);
    }
    
    private void drawNodeImages(Graphics2D g2d, Node node, Rectangle nodeRect) {
        int imageY = nodeRect.y + 35;
        int imageSize = 60;
        int spacing = 5;
        
        // Input 이미지들 표시
        if (node.getInputImages() != null && !node.getInputImages().isEmpty()) {
            g2d.setColor(Color.CYAN);
            g2d.setFont(new Font("SansSerif", Font.BOLD, 8));
            g2d.drawString("INPUT", nodeRect.x + 10, imageY - 5);
            
            int inputImagesPerRow = Math.min(4, node.getInputImages().size());
            int inputRowHeight = imageSize + spacing;
            
            for (int i = 0; i < node.getInputImages().size(); i++) {
                int row = i / inputImagesPerRow;
                int col = i % inputImagesPerRow;
                
                int x = nodeRect.x + 10 + col * (imageSize + spacing);
                int y = imageY + row * inputRowHeight;
                
                if (node.getInputImages().get(i) != null) {
                    g2d.drawImage(node.getInputImages().get(i), x, y, imageSize, imageSize, null);
                    
                    if (i < node.getInputImageNames().size()) {
                        String imageName = node.getInputImageNames().get(i);
                        if (imageName != null && !imageName.isEmpty()) {
                            g2d.setFont(new Font("SansSerif", Font.PLAIN, 6));
                            g2d.setColor(Color.WHITE);
                            String displayName = getFileNameWithoutExtension(imageName);
                            g2d.drawString(displayName, x, y + imageSize + 12);
                        }
                    }
                } else {
                    g2d.setColor(Color.DARK_GRAY);
                    g2d.fillRect(x, y, imageSize, imageSize);
                    g2d.setColor(Color.GRAY);
                    g2d.drawRect(x, y, imageSize, imageSize);
                }
            }
            
            imageY += ((node.getInputImages().size() - 1) / inputImagesPerRow + 1) * inputRowHeight + 20;
        }
        
        // Output 이미지들 표시
        if (node.getOutputImages() != null && !node.getOutputImages().isEmpty()) {
            g2d.setColor(Color.ORANGE);
            g2d.setFont(new Font("SansSerif", Font.BOLD, 8));
            g2d.drawString("OUTPUT", nodeRect.x + 10, imageY - 5);
            
            int outputImagesPerRow = Math.min(4, node.getOutputImages().size());
            
            for (int i = 0; i < node.getOutputImages().size(); i++) {
                int row = i / outputImagesPerRow;
                int col = i % outputImagesPerRow;
                
                int x = nodeRect.x + 10 + col * (imageSize + spacing);
                int y = imageY + row * (imageSize + spacing);
                
                if (node.getOutputImages().get(i) != null) {
                    // GIF 파일인 경우 더 크게 표시
                    if ((node.getType() == NodeType.STEP04 || node.getType() == NodeType.STEP05) && 
                        i < node.getOutputImageNames().size() && 
                        node.getOutputImageNames().get(i).toLowerCase().endsWith(".gif")) {
                        
                        int gifSize = imageSize * 2;
                        g2d.drawImage(node.getOutputImages().get(i), x, y, gifSize, gifSize, null);
                        
                        g2d.setFont(new Font("SansSerif", Font.BOLD, 8));
                        g2d.setColor(Color.YELLOW);
                        String displayName = getFileNameWithoutExtension(node.getOutputImageNames().get(i));
                        g2d.drawString(displayName, x, y + gifSize + 15);
                    } else {
                        g2d.drawImage(node.getOutputImages().get(i), x, y, imageSize, imageSize, null);
                        
                        if (i < node.getOutputImageNames().size()) {
                            String imageName = node.getOutputImageNames().get(i);
                            if (imageName != null && !imageName.isEmpty()) {
                                g2d.setFont(new Font("SansSerif", Font.PLAIN, 6));
                                g2d.setColor(Color.WHITE);
                                String displayName = getFileNameWithoutExtension(imageName);
                                g2d.drawString(displayName, x, y + imageSize + 12);
                            }
                        }
                    }
                } else {
                    g2d.setColor(Color.DARK_GRAY);
                    g2d.fillRect(x, y, imageSize, imageSize);
                    g2d.setColor(Color.GRAY);
                    g2d.drawRect(x, y, imageSize, imageSize);
                }
            }
        }
    }
    
    private String getFileNameWithoutExtension(String fileName) {
        int dotIndex = fileName.lastIndexOf('.');
        if (dotIndex > 0) {
            return fileName.substring(0, dotIndex);
        }
        return fileName;
    }
    
    private void drawNodePorts(Graphics2D g2d, Node node, Rectangle nodeRect) {
        int portY = nodeRect.y + nodeRect.height - 30;
        
        // Input 포트
        for (NodePort port : node.getInputPorts()) {
            Point portPos = new Point(nodeRect.x - 8, portY);
            drawPort(g2d, port, portPos);
            
            g2d.setColor(Color.LIGHT_GRAY);
            g2d.setFont(new Font("SansSerif", Font.PLAIN, 9));
            g2d.drawString(port.getName(), nodeRect.x + 15, portY + 5);
        }
        
        // Output 포트
        for (NodePort port : node.getOutputPorts()) {
            Point portPos = new Point(nodeRect.x + nodeRect.width - 8, portY);
            drawPort(g2d, port, portPos);
            
            g2d.setColor(Color.LIGHT_GRAY);
            g2d.setFont(new Font("SansSerif", Font.PLAIN, 9));
            FontMetrics fm = g2d.getFontMetrics();
            g2d.drawString(port.getName(), 
                nodeRect.x + nodeRect.width - fm.stringWidth(port.getName()) - 15, 
                portY + 5);
        }
    }
    
    private void drawPort(Graphics2D g2d, NodePort port, Point position) {
        Rectangle portRect = new Rectangle(position.x - 8, position.y - 8, 16, 16);
        port.setBounds(portRect);
        
        Color portColor = port.getType() == PortType.INPUT ? Color.CYAN : Color.ORANGE;
        
        g2d.setColor(portColor);
        g2d.fillOval(portRect.x, portRect.y, portRect.width, portRect.height);
        
        g2d.setColor(Color.WHITE);
        g2d.setStroke(new BasicStroke(2));
        g2d.drawOval(portRect.x, portRect.y, portRect.width, portRect.height);
    }
    
    private void drawConnection(Graphics2D g2d, Connection connection) {
        Point startPos = getPortCenter(connection.getOutputPort());
        Point endPos = getPortCenter(connection.getInputPort());
        
        boolean isHighlighted = isConnectionNearMouse(connection, lastMousePos);
        Color connectionColor = isHighlighted ? Color.RED : Color.YELLOW;
        int lineWidth = isHighlighted ? 4 : 3;
        
        drawBezierConnection(g2d, startPos, endPos, connectionColor, lineWidth);
    }
    
    private void drawTempConnection(Graphics2D g2d, NodePort startPort, Point mousePos) {
        Point startPos = getPortCenter(startPort);
        Point endPos = new Point(
            (int)((mousePos.x - canvasOffset.x) / zoomLevel),
            (int)((mousePos.y - canvasOffset.y) / zoomLevel)
        );
        
        drawBezierConnection(g2d, startPos, endPos, Color.GRAY, 2);
    }
    
    private void drawBezierConnection(Graphics2D g2d, Point start, Point end, Color color, int lineWidth) {
        g2d.setColor(color);
        g2d.setStroke(new BasicStroke(lineWidth));
        
        int controlOffset = Math.abs(end.x - start.x) / 2;
        Point control1 = new Point(start.x + controlOffset, start.y);
        Point control2 = new Point(end.x - controlOffset, end.y);
        
        CubicCurve2D curve = new CubicCurve2D.Float(
            start.x, start.y,
            control1.x, control1.y,
            control2.x, control2.y,
            end.x, end.y
        );
        
        g2d.draw(curve);
    }
    
    private Point getPortCenter(NodePort port) {
        Rectangle bounds = port.getBounds();
        return new Point(
            bounds.x + bounds.width / 2,
            bounds.y + bounds.height / 2
        );
    }
    
    private int getNodeWidth(Node node) {
        int maxImages = Math.max(
            node.getInputImages() != null ? node.getInputImages().size() : 0,
            node.getOutputImages() != null ? node.getOutputImages().size() : 0
        );
        int imagesPerRow = Math.min(4, maxImages);
        int baseWidth = Math.max(200, 20 + imagesPerRow * 65);
        
        // Step04나 Step05에서 GIF가 있는 경우 최소 너비 보장
        if ((node.getType() == NodeType.STEP04 || node.getType() == NodeType.STEP05) && 
            node.getOutputImages() != null) {
            boolean hasGif = false;
            for (int i = 0; i < node.getOutputImages().size(); i++) {
                if (i < node.getOutputImageNames().size() && 
                    node.getOutputImageNames().get(i).toLowerCase().endsWith(".gif")) {
                    hasGif = true;
                    break;
                }
            }
            
            if (hasGif) {
                baseWidth = Math.max(baseWidth, 300);
            }
        }
        
        return baseWidth;
    }
    
    private int getNodeHeight(Node node) {
        int inputRows = node.getInputImages() != null ? 
            (node.getInputImages().size() - 1) / 4 + 1 : 0;
        int outputRows = node.getOutputImages() != null ? 
            (node.getOutputImages().size() - 1) / 4 + 1 : 0;
        
        int baseHeight = 80;
        int imageHeight = (inputRows + outputRows) * 80;
        
        if (inputRows > 0) imageHeight += 20;
        if (outputRows > 0) imageHeight += 20;
        
        // Step04나 Step05에서 GIF가 있는 경우 추가 높이 계산
        if ((node.getType() == NodeType.STEP04 || node.getType() == NodeType.STEP05) && 
            node.getOutputImages() != null) {
            boolean hasGif = false;
            for (int i = 0; i < node.getOutputImages().size(); i++) {
                if (i < node.getOutputImageNames().size() && 
                    node.getOutputImageNames().get(i).toLowerCase().endsWith(".gif")) {
                    hasGif = true;
                    break;
                }
            }
            
            if (hasGif) {
                imageHeight += 120; // GIF 확대를 위한 추가 공간
            }
        }
        
        return Math.max(baseHeight, baseHeight + imageHeight);
    }
    
    private Color getNodeColor(NodeType type) {
        switch (type) {
            case ORIGINAL: return new Color(70, 130, 180);
            case STEP01: return new Color(220, 20, 60);
            case STEP02: return new Color(255, 140, 0);
            case STEP03: return new Color(50, 205, 50);
            case STEP04: return new Color(138, 43, 226);
            case STEP05: return new Color(255, 20, 147);
            default: return new Color(70, 70, 74);
        }
    }
    
    private Node getNodeAtPosition(Point position) {
        Point adjustedPos = new Point(
            (int)((position.x - canvasOffset.x) / zoomLevel),
            (int)((position.y - canvasOffset.y) / zoomLevel)
        );
        
        for (int i = nodes.size() - 1; i >= 0; i--) {
            Node node = nodes.get(i);
            int nodeWidth = getNodeWidth(node);
            int nodeHeight = getNodeHeight(node);
            Rectangle nodeRect = new Rectangle(node.getPosition().x, node.getPosition().y, nodeWidth, nodeHeight);
            if (nodeRect.contains(adjustedPos)) {
                return node;
            }
        }
        return null;
    }
    
    private NodePort getPortAtPosition(Point position) {
        Point adjustedPos = new Point(
            (int)((position.x - canvasOffset.x) / zoomLevel),
            (int)((position.y - canvasOffset.y) / zoomLevel)
        );
        
        for (Node node : nodes) {
            for (NodePort port : node.getInputPorts()) {
                if (port.getBounds() != null && port.getBounds().contains(adjustedPos)) {
                    return port;
                }
            }
            for (NodePort port : node.getOutputPorts()) {
                if (port.getBounds() != null && port.getBounds().contains(adjustedPos)) {
                    return port;
                }
            }
        }
        return null;
    }
    
    private Connection getConnectionAtPosition(Point position) {
        Point adjustedPos = new Point(
            (int)((position.x - canvasOffset.x) / zoomLevel),
            (int)((position.y - canvasOffset.y) / zoomLevel)
        );
        
        for (Connection connection : connections) {
            if (isPointOnConnection(connection, adjustedPos)) {
                return connection;
            }
        }
        return null;
    }
    
    private boolean isPointOnConnection(Connection connection, Point point) {
        Point startPos = getPortCenter(connection.getOutputPort());
        Point endPos = getPortCenter(connection.getInputPort());
        
        int controlOffset = Math.abs(endPos.x - startPos.x) / 2;
        Point control1 = new Point(startPos.x + controlOffset, startPos.y);
        Point control2 = new Point(endPos.x - controlOffset, endPos.y);
        
        final int segments = 20;
        final double threshold = 10.0;
        
        for (int i = 0; i <= segments; i++) {
            double t = (double)i / segments;
            Point bezierPoint = calculateBezierPoint(startPos, control1, control2, endPos, t);
            
            double distance = Math.sqrt(Math.pow(point.x - bezierPoint.x, 2) + Math.pow(point.y - bezierPoint.y, 2));
            if (distance <= threshold) {
                return true;
            }
        }
        
        return false;
    }
    
    private boolean isConnectionNearMouse(Connection connection, Point mousePos) {
        Point adjustedPos = new Point(
            (int)((mousePos.x - canvasOffset.x) / zoomLevel),
            (int)((mousePos.y - canvasOffset.y) / zoomLevel)
        );
        
        return isPointOnConnection(connection, adjustedPos);
    }
    
    private Point calculateBezierPoint(Point p0, Point p1, Point p2, Point p3, double t) {
        double u = 1 - t;
        double tt = t * t;
        double uu = u * u;
        double uuu = uu * u;
        double ttt = tt * t;
        
        double x = uuu * p0.x + 3 * uu * t * p1.x + 3 * u * tt * p2.x + ttt * p3.x;
        double y = uuu * p0.y + 3 * uu * t * p1.y + 3 * u * tt * p2.y + ttt * p3.y;
        
        return new Point((int)x, (int)y);
    }
    
    private boolean canConnect(NodePort port1, NodePort port2) {
        if (port1.getType() == port2.getType()) {
            return false;
        }
        
        for (Connection connection : connections) {
            if ((connection.getOutputPort() == port1 && connection.getInputPort() == port2) ||
                (connection.getOutputPort() == port2 && connection.getInputPort() == port1)) {
                return false;
            }
        }
        
        return true;
    }
    
    private void processImageFlow(NodePort outputPort, NodePort inputPort) {
        NodePort fromPort = outputPort.getType() == PortType.OUTPUT ? outputPort : inputPort;
        NodePort toPort = outputPort.getType() == PortType.INPUT ? outputPort : inputPort;
        
        Node fromNode = fromPort.getParentNode();
        Node toNode = toPort.getParentNode();
        
        processSpecificNodeConnection(fromNode, toNode);
        repaint();
    }
    
    private void processSpecificNodeConnection(Node fromNode, Node toNode) {
        switch (toNode.getType()) {
            case STEP01:
                if (fromNode.getType() == NodeType.ORIGINAL) {
                    toNode.setInputImages(fromNode.getOutputImages(), fromNode.getOutputImageNames());
                    toNode.loadImages(new String[] {
                        "images/debug_full_mask.png",
                        "images/background.png", 
                        "images/output_no_bg.png"
                    }, false);
                }
                break;
                
            case STEP02:
                if (fromNode.getType() == NodeType.STEP01) {
                    List<BufferedImage> selectedImages = new ArrayList<>();
                    List<String> selectedNames = new ArrayList<>();
                    
                    if (fromNode.getOutputImages().size() >= 2) {
                        selectedImages.add(fromNode.getOutputImages().get(0));
                        selectedImages.add(fromNode.getOutputImages().get(1));
                        selectedNames.add("images/debug_full_mask.png");
                        selectedNames.add("images/background.png");
                    }
                    
                    toNode.setInputImages(selectedImages, selectedNames);
                    toNode.loadImages(new String[] { "images/lama_output.png" }, false);
                }
                break;
                
            case STEP03:
                if (fromNode.getType() == NodeType.ORIGINAL) {
                    List<BufferedImage> combinedImages = new ArrayList<>(fromNode.getOutputImages());
                    List<String> combinedNames = new ArrayList<>(fromNode.getOutputImageNames());
                    
                    // emoji_rabbit.png 이미지 로드
                    BufferedImage emojiImage = loadEmojiImage();
                    combinedImages.add(emojiImage);
                    combinedNames.add("emoji_rabbit.png");
                    
                    toNode.setInputImages(combinedImages, combinedNames);
                    toNode.loadImages(new String[] { "images/output.png" }, false);
                }
                break;
                
            case STEP04:
                if (fromNode.getType() == NodeType.STEP01) {
                    List<BufferedImage> selectedImages = new ArrayList<>();
                    List<String> selectedNames = new ArrayList<>();
                    
                    if (fromNode.getOutputImages().size() >= 3) {
                        selectedImages.add(fromNode.getOutputImages().get(2));
                        selectedNames.add("images/output_no_bg.png");
                    }
                    
                    toNode.setInputImages(selectedImages, selectedNames);
                    
                    String[] step04Outputs = new String[] {
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
                    
                    toNode.loadImages(step04Outputs, false);
                }
                break;
                
            case STEP05:
                if (fromNode.getType() == NodeType.STEP04) {
                    List<BufferedImage> selectedImages = new ArrayList<>();
                    List<String> selectedNames = new ArrayList<>();
                    
                    if (fromNode.getOutputImages().size() >= 8) {
                        for (int i = 0; i < 8; i++) {
                            selectedImages.add(fromNode.getOutputImages().get(i));
                            selectedNames.add(fromNode.getOutputImageNames().get(i));
                        }
                    }
                    
                    toNode.setInputImages(selectedImages, selectedNames);
                    toNode.loadImages(new String[] { "images/step05_sc_2025-08-11.gif" }, false);
                }
                break;
        }
    }
    
    private BufferedImage loadEmojiImage() {
        String emojiPath = "images/emoji_rabbit.png";
        
        try {
            File emojiFile = new File(emojiPath);
            if (emojiFile.exists()) {
                return ImageIO.read(emojiFile);
            } else {
                // 상대 경로로도 시도
                emojiFile = new File(System.getProperty("user.dir"), emojiPath);
                if (emojiFile.exists()) {
                    return ImageIO.read(emojiFile);
                }
            }
        } catch (IOException e) {
            System.err.println("이미지 로드 실패: " + emojiPath + " - " + e.getMessage());
        }
        
        // 파일이 없으면 플레이스홀더 생성
        return createPlaceholderImage("emoji_rabbit.png", Color.YELLOW);
    }
    
    private BufferedImage createPlaceholderImage(String fileName, Color backgroundColor) {
        BufferedImage image = new BufferedImage(100, 80, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = image.createGraphics();
        
        g2d.setColor(backgroundColor);
        g2d.fillRect(0, 0, 100, 80);
        
        g2d.setColor(Color.BLACK);
        g2d.setFont(new Font("SansSerif", Font.BOLD, 8));
        
        String displayName = getFileNameWithoutExtension(fileName);
        if (displayName.length() > 12) {
            displayName = displayName.substring(0, 12) + "...";
        }
        
        FontMetrics fm = g2d.getFontMetrics();
        int textWidth = fm.stringWidth(displayName);
        int textHeight = fm.getHeight();
        
        g2d.drawString(displayName, (100 - textWidth) / 2, (80 + textHeight) / 2);
        g2d.drawRect(0, 0, 99, 79);
        
        g2d.dispose();
        return image;
    }
    
    private void removeConnection(Connection connection) {
        if (connections.contains(connection)) {
            connections.remove(connection);
            resetNodeAfterDisconnection(connection.getInputPort().getParentNode());
        }
    }
    
    private void resetNodeAfterDisconnection(Node node) {
        node.getInputImages().clear();
        node.getInputImageNames().clear();
        
        boolean hasOutputConnection = connections.stream()
            .anyMatch(c -> c.getOutputPort().getParentNode() == node);
            
        if (!hasOutputConnection && node.getType() != NodeType.ORIGINAL) {
            node.getOutputImages().clear();
            node.getOutputImageNames().clear();
        }
    }
    
    public void clearAllConnections() {
        connections.clear();
        
        for (Node node : nodes) {
            if (node.getType() != NodeType.ORIGINAL) {
                node.getInputImages().clear();
                node.getInputImageNames().clear();
                node.getOutputImages().clear();
                node.getOutputImageNames().clear();
            }
        }
        
        repaint();
    }
    
    public void resetAllNodes() {
        connections.clear();
        
        for (Node node : nodes) {
            node.getInputImages().clear();
            node.getInputImageNames().clear();
            node.getOutputImages().clear();
            node.getOutputImageNames().clear();
            
            if (node.getType() == NodeType.ORIGINAL) {
                node.loadImages(new String[] { "images/input.png" }, false);
            }
        }
        
        repaint();
    }
    
    public void cleanupAnimations() {
        if (animationTimer != null) {
            animationTimer.stop();
        }
        animatedImages.clear();
    }
}

// ================= Node 클래스 =================
class Node {
    private String title;
    private Point position;
    private List<NodePort> inputPorts;
    private List<NodePort> outputPorts;
    private List<BufferedImage> inputImages;
    private List<BufferedImage> outputImages;
    private List<String> inputImageNames;
    private List<String> outputImageNames;
    private NodeType type;
    
    public Node(String title, Point position, NodeType type) {
        this.title = title;
        this.position = position;
        this.type = type;
        this.inputPorts = new ArrayList<>();
        this.outputPorts = new ArrayList<>();
        this.inputImages = new ArrayList<>();
        this.outputImages = new ArrayList<>();
        this.inputImageNames = new ArrayList<>();
        this.outputImageNames = new ArrayList<>();
    }
    
    // Getters
    public String getTitle() { return title; }
    public Point getPosition() { return position; }
    public List<NodePort> getInputPorts() { return inputPorts; }
    public List<NodePort> getOutputPorts() { return outputPorts; }
    public List<BufferedImage> getInputImages() { return inputImages; }
    public List<BufferedImage> getOutputImages() { return outputImages; }
    public List<String> getInputImageNames() { return inputImageNames; }
    public List<String> getOutputImageNames() { return outputImageNames; }
    public NodeType getType() { return type; }
    
    // Setters
    public void setTitle(String title) { this.title = title; }
    public void setPosition(Point position) { this.position = position; }
    public void setType(NodeType type) { this.type = type; }
    
    public void loadImages(String[] imageFileNames, boolean isInput) {
        List<BufferedImage> images = isInput ? inputImages : outputImages;
        List<String> imageNames = isInput ? inputImageNames : outputImageNames;
        
        // 기존 이미지들 정리
        images.clear();
        imageNames.clear();
        
        for (String fileName : imageFileNames) {
            try {
                BufferedImage image;
                File imageFile = new File(fileName);
                
                if (imageFile.exists()) {
                    image = ImageIO.read(imageFile);
                } else {
                    // 상대 경로로도 시도
                    imageFile = new File(System.getProperty("user.dir"), fileName);
                    if (imageFile.exists()) {
                        image = ImageIO.read(imageFile);
                    } else {
                        Color placeholderColor = getPlaceholderColor(fileName);
                        image = createPlaceholderImage(fileName, placeholderColor);
                    }
                }
                
                images.add(image);
                imageNames.add(fileName);
            } catch (IOException ex) {
                System.err.println("이미지 로드 실패:");
                System.err.println("  파일명: " + fileName);
                System.err.println("  오류: " + ex.getMessage());
                
                BufferedImage errorImage = createPlaceholderImage("ERROR: " + getFileNameOnly(fileName), Color.RED);
                images.add(errorImage);
                imageNames.add(fileName);
            }
        }
    }
    
    public void setInputImages(List<BufferedImage> images, List<String> imageNames) {
        inputImages.clear();
        inputImageNames.clear();
        
        if (images != null) {
            inputImages.addAll(images);
        }
        
        if (imageNames != null) {
            inputImageNames.addAll(imageNames);
        }
    }
    
    private Color getPlaceholderColor(String fileName) {
        String lowerFileName = fileName.toLowerCase();
        
        if (lowerFileName.contains("input")) return Color.CYAN;
        if (lowerFileName.contains("mask")) return new Color(128, 0, 128); // Purple
        if (lowerFileName.contains("background")) return Color.GREEN;
        if (lowerFileName.contains("output")) return Color.ORANGE;
        if (lowerFileName.contains("lama")) return Color.CYAN;
        if (lowerFileName.contains("emoji")) return Color.YELLOW;
        if (lowerFileName.contains("360")) return Color.PINK;
        if (lowerFileName.contains("gif")) return Color.MAGENTA;
        if (lowerFileName.contains("step05")) return Color.GREEN;
        
        return Color.GRAY;
    }
    
    private BufferedImage createPlaceholderImage(String fileName, Color backgroundColor) {
        BufferedImage image = new BufferedImage(100, 80, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = image.createGraphics();
        
        g2d.setColor(backgroundColor);
        g2d.fillRect(0, 0, 100, 80);
        
        g2d.setColor(Color.BLACK);
        g2d.setFont(new Font("SansSerif", Font.BOLD, 7));
        
        String displayName = getFileNameWithoutExtension(fileName);
        if (displayName.length() > 15) {
            displayName = displayName.substring(0, 15) + "...";
        }
        
        FontMetrics fm = g2d.getFontMetrics();
        int textWidth = fm.stringWidth(displayName);
        int textHeight = fm.getHeight();
        
        int x = Math.max(2, (100 - textWidth) / 2);
        int y = Math.max(2, (80 + textHeight) / 2);
        
        g2d.drawString(displayName, x, y);
        g2d.drawRect(0, 0, 99, 79);
        
        g2d.dispose();
        return image;
    }
    
    private String getFileNameWithoutExtension(String fileName) {
        int dotIndex = fileName.lastIndexOf('.');
        if (dotIndex > 0) {
            return fileName.substring(0, dotIndex);
        }
        return fileName;
    }
    
    private String getFileNameOnly(String fullPath) {
        int slashIndex = Math.max(fullPath.lastIndexOf('/'), fullPath.lastIndexOf('\\'));
        if (slashIndex >= 0) {
            return fullPath.substring(slashIndex + 1);
        }
        return fullPath;
    }
    
    public void dispose() {
        // Input 이미지들 정리
        for (BufferedImage img : inputImages) {
            if (img != null) {
                img.flush();
            }
        }
        inputImages.clear();
        
        // Output 이미지들 정리
        for (BufferedImage img : outputImages) {
            if (img != null) {
                img.flush();
            }
        }
        outputImages.clear();
    }
}

// ================= NodeType 열거형 =================
enum NodeType {
    ORIGINAL,
    STEP01,
    STEP02,
    STEP03,
    STEP04,
    STEP05
}

// ================= NodePort 클래스 =================
class NodePort {
    private String name;
    private PortType type;
    private Node parentNode;
    private Rectangle bounds;
    
    public NodePort(String name, PortType type, Node parentNode) {
        this.name = name;
        this.type = type;
        this.parentNode = parentNode;
    }
    
    // Getters
    public String getName() { return name; }
    public PortType getType() { return type; }
    public Node getParentNode() { return parentNode; }
    public Rectangle getBounds() { return bounds; }
    
    // Setters
    public void setName(String name) { this.name = name; }
    public void setType(PortType type) { this.type = type; }
    public void setParentNode(Node parentNode) { this.parentNode = parentNode; }
    public void setBounds(Rectangle bounds) { this.bounds = bounds; }
}

// ================= PortType 열거형 =================
enum PortType {
    INPUT,
    OUTPUT
}

// ================= Connection 클래스 =================
class Connection {
    private NodePort outputPort;
    private NodePort inputPort;
    
    public Connection(NodePort outputPort, NodePort inputPort) {
        if (outputPort.getType() == PortType.OUTPUT && inputPort.getType() == PortType.INPUT) {
            this.outputPort = outputPort;
            this.inputPort = inputPort;
        } else {
            this.outputPort = inputPort.getType() == PortType.OUTPUT ? inputPort : outputPort;
            this.inputPort = inputPort.getType() == PortType.INPUT ? inputPort : outputPort;
        }
    }
    
    // Getters
    public NodePort getOutputPort() { return outputPort; }
    public NodePort getInputPort() { return inputPort; }
    
    // Setters
    public void setOutputPort(NodePort outputPort) { this.outputPort = outputPort; }
    public void setInputPort(NodePort inputPort) { this.inputPort = inputPort; }
}