! OpenGL Node-based GUI in Fortran using GLUT and OpenGL
! Compile with: g95 -o node_gui.exe node_gui.f90 opengl.f90 -lopengl32 -lglu32 -lfreeglut

!---------------------------------------------------------------
! Made by : ravendev ( dwfree74@naver.com / elca6659@gmail.com)
!           https://github.com/ravendev-team/ravendev-ai
!---------------------------------------------------------------

module node_gui_data
    implicit none
    
    ! Window dimensions
    integer, parameter :: WINDOW_WIDTH = 800
    integer, parameter :: WINDOW_HEIGHT = 600
    
    ! Node structure
    type :: node_type
        real :: x, y          ! Position
        real :: width, height ! Size
        integer :: node_id    ! Node identifier
        character(len=20) :: title
        logical :: is_dragging ! Drag state
        real :: color_r, color_g, color_b ! Node color
    end type node_type
    
    ! Global variables
    type(node_type) :: nodes(6)
    integer :: num_nodes
    integer :: dragging_node
    integer :: last_mouse_x, last_mouse_y
    logical :: mouse_pressed
    
    ! Camera/view variables
    real :: zoom_level = 1.0
    real :: pan_x = 0.0, pan_y = 0.0

end module node_gui_data

! Utility subroutines
subroutine initialize_nodes()
    use node_gui_data
    implicit none
    
    num_nodes = 6
    dragging_node = 0
    mouse_pressed = .false.
    
    ! Original Image Node
    nodes(1)%x = 50.0
    nodes(1)%y = 50.0
    nodes(1)%width = 120.0
    nodes(1)%height = 80.0
    nodes(1)%node_id = 1
    nodes(1)%title = 'Original Image'
    nodes(1)%is_dragging = .false.
    nodes(1)%color_r = 0.5
    nodes(1)%color_g = 0.7
    nodes(1)%color_b = 1.0
    
    ! Step01 Node
    nodes(2)%x = 250.0
    nodes(2)%y = 50.0
    nodes(2)%width = 120.0
    nodes(2)%height = 80.0
    nodes(2)%node_id = 2
    nodes(2)%title = 'Step01'
    nodes(2)%is_dragging = .false.
    nodes(2)%color_r = 0.8
    nodes(2)%color_g = 0.1
    nodes(2)%color_b = 0.2
    
    ! Step02 Node
    nodes(3)%x = 450.0
    nodes(3)%y = 50.0
    nodes(3)%width = 120.0
    nodes(3)%height = 80.0
    nodes(3)%node_id = 3
    nodes(3)%title = 'Step02'
    nodes(3)%is_dragging = .false.
    nodes(3)%color_r = 1.0
    nodes(3)%color_g = 0.5
    nodes(3)%color_b = 0.0
    
    ! Step03 Node
    nodes(4)%x = 250.0
    nodes(4)%y = 200.0
    nodes(4)%width = 120.0
    nodes(4)%height = 80.0
    nodes(4)%node_id = 4
    nodes(4)%title = 'Step03'
    nodes(4)%is_dragging = .false.
    nodes(4)%color_r = 0.2
    nodes(4)%color_g = 0.8
    nodes(4)%color_b = 0.2
    
    ! Step04 Node
    nodes(5)%x = 450.0
    nodes(5)%y = 200.0
    nodes(5)%width = 120.0
    nodes(5)%height = 80.0
    nodes(5)%node_id = 5
    nodes(5)%title = 'Step04'
    nodes(5)%is_dragging = .false.
    nodes(5)%color_r = 0.5
    nodes(5)%color_g = 0.2
    nodes(5)%color_b = 0.8
    
    ! Step05 Node
    nodes(6)%x = 650.0
    nodes(6)%y = 200.0
    nodes(6)%width = 120.0
    nodes(6)%height = 80.0
    nodes(6)%node_id = 6
    nodes(6)%title = 'Step05'
    nodes(6)%is_dragging = .false.
    nodes(6)%color_r = 0.9
    nodes(6)%color_g = 0.1
    nodes(6)%color_b = 0.6
    
end subroutine initialize_nodes

subroutine draw_grid()
    use OpenGL
    implicit none
    integer :: i
    real, parameter :: grid_size = 20.0
    integer, parameter :: grid_lines = 50
    
    call glColor3f(0.25, 0.25, 0.3)
    call glBegin(GL_LINES)
    
    ! Vertical lines
    do i = 0, grid_lines
        call glVertex2f(real(i) * grid_size, 0.0)
        call glVertex2f(real(i) * grid_size, real(grid_lines) * grid_size)
    end do
    
    ! Horizontal lines
    do i = 0, grid_lines
        call glVertex2f(0.0, real(i) * grid_size)
        call glVertex2f(real(grid_lines) * grid_size, real(i) * grid_size)
    end do
    
    call glEnd()
    
end subroutine draw_grid

subroutine draw_node(node_idx)
    use OpenGL
    use node_gui_data
    implicit none
    integer, intent(in) :: node_idx
    real :: x1, y1, x2, y2
    real :: brightness
    
    x1 = nodes(node_idx)%x
    y1 = nodes(node_idx)%y
    x2 = nodes(node_idx)%x + nodes(node_idx)%width
    y2 = nodes(node_idx)%y + nodes(node_idx)%height
    
    ! Add brightness if being dragged
    brightness = 1.0
    if (nodes(node_idx)%is_dragging) brightness = 1.3
    
    ! Draw node background with gradient effect
    call glBegin(GL_QUADS)
    
    ! Top edge (brighter)
    call glColor3f(nodes(node_idx)%color_r * brightness, &
                   nodes(node_idx)%color_g * brightness, &
                   nodes(node_idx)%color_b * brightness)
    call glVertex2f(x1, y1)
    call glVertex2f(x2, y1)
    
    ! Bottom edge (darker)
    call glColor3f(nodes(node_idx)%color_r * 0.7, &
                   nodes(node_idx)%color_g * 0.7, &
                   nodes(node_idx)%color_b * 0.7)
    call glVertex2f(x2, y2)
    call glVertex2f(x1, y2)
    
    call glEnd()
    
    ! Draw node border
    call glColor3f(0.8, 0.8, 0.9)
    call glLineWidth(2.0)
    call glBegin(GL_LINE_LOOP)
    call glVertex2f(x1, y1)
    call glVertex2f(x2, y1)
    call glVertex2f(x2, y2)
    call glVertex2f(x1, y2)
    call glEnd()
    
    ! Draw input/output ports
    call draw_ports(node_idx)
    
    ! Draw node title (simplified - just a colored rectangle for now)
    call glColor3f(1.0, 1.0, 1.0)
    call glBegin(GL_QUADS)
    call glVertex2f(x1 + 5, y1 + 5)
    call glVertex2f(x2 - 5, y1 + 5)
    call glVertex2f(x2 - 5, y1 + 20)
    call glVertex2f(x1 + 5, y1 + 20)
    call glEnd()
    
end subroutine draw_node

subroutine draw_ports(node_idx)
    use OpenGL
    use node_gui_data
    implicit none
    integer, intent(in) :: node_idx
    real :: port_size = 8.0
    real :: input_x, output_x, port_y
    
    input_x = nodes(node_idx)%x - port_size/2
    output_x = nodes(node_idx)%x + nodes(node_idx)%width - port_size/2
    port_y = nodes(node_idx)%y + nodes(node_idx)%height - 20.0
    
    ! Draw input port (blue)
    if (nodes(node_idx)%node_id > 1) then
        call glColor3f(0.3, 0.6, 1.0)
        call glBegin(GL_QUADS)
        call glVertex2f(input_x, port_y)
        call glVertex2f(input_x + port_size, port_y)
        call glVertex2f(input_x + port_size, port_y + port_size)
        call glVertex2f(input_x, port_y + port_size)
        call glEnd()
    end if
    
    ! Draw output port (orange) - all nodes have output
    call glColor3f(1.0, 0.6, 0.2)
    call glBegin(GL_QUADS)
    call glVertex2f(output_x, port_y)
    call glVertex2f(output_x + port_size, port_y)
    call glVertex2f(output_x + port_size, port_y + port_size)
    call glVertex2f(output_x, port_y + port_size)
    call glEnd()
    
end subroutine draw_ports

subroutine draw_connections()
    use OpenGL
    use node_gui_data
    implicit none
    
    call glColor3f(1.0, 1.0, 0.3)
    call glLineWidth(3.0)
    
    ! Draw predefined connections (simplified)
    call draw_bezier_line(1, 2)  ! Original -> Step01
    call draw_bezier_line(2, 3)  ! Step01 -> Step02
    call draw_bezier_line(1, 4)  ! Original -> Step03
    call draw_bezier_line(2, 5)  ! Step01 -> Step04
    call draw_bezier_line(5, 6)  ! Step04 -> Step05
    
end subroutine draw_connections

subroutine draw_bezier_line(node1_idx, node2_idx)
    use OpenGL
    use node_gui_data
    implicit none
    integer, intent(in) :: node1_idx, node2_idx
    real :: start_x, start_y, end_x, end_y
    real :: ctrl1_x, ctrl1_y, ctrl2_x, ctrl2_y
    real :: t, x, y
    integer :: i, segments = 20
    
    ! Calculate connection points
    start_x = nodes(node1_idx)%x + nodes(node1_idx)%width
    start_y = nodes(node1_idx)%y + nodes(node1_idx)%height - 20.0 + 4.0
    end_x = nodes(node2_idx)%x
    end_y = nodes(node2_idx)%y + nodes(node2_idx)%height - 20.0 + 4.0
    
    ! Calculate control points for bezier curve
    ctrl1_x = start_x + 50.0
    ctrl1_y = start_y
    ctrl2_x = end_x - 50.0
    ctrl2_y = end_y
    
    ! Draw bezier curve using line segments
    call glBegin(GL_LINE_STRIP)
    do i = 0, segments
        t = real(i) / real(segments)
        call bezier_point(start_x, start_y, ctrl1_x, ctrl1_y, &
                        ctrl2_x, ctrl2_y, end_x, end_y, t, x, y)
        call glVertex2f(x, y)
    end do
    call glEnd()
    
end subroutine draw_bezier_line

subroutine bezier_point(p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y, t, x, y)
    implicit none
    real, intent(in) :: p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y, t
    real, intent(out) :: x, y
    real :: u, tt, uu, uuu, ttt
    
    u = 1.0 - t
    tt = t * t
    uu = u * u
    uuu = uu * u
    ttt = tt * t
    
    x = uuu * p0x + 3 * uu * t * p1x + 3 * u * tt * p2x + ttt * p3x
    y = uuu * p0y + 3 * uu * t * p1y + 3 * u * tt * p2y + ttt * p3y
    
end subroutine bezier_point

! Callback functions
subroutine display() bind(C)
    use OpenGL
    use node_gui_data
    implicit none
    integer :: i
    
    ! Clear the screen
    call glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)
    
    ! Setup 2D orthographic projection
    call glMatrixMode(GL_PROJECTION)
    call glLoadIdentity()
    call glOrtho(0.0d0, dble(WINDOW_WIDTH), dble(WINDOW_HEIGHT), 0.0d0, -1.0d0, 1.0d0)
    
    call glMatrixMode(GL_MODELVIEW)
    call glLoadIdentity()
    
    ! Apply zoom and pan
    call glScalef(zoom_level, zoom_level, 1.0)
    call glTranslatef(pan_x, pan_y, 0.0)
    
    ! Draw grid
    call draw_grid()
    
    ! Draw connections between nodes
    call draw_connections()
    
    ! Draw all nodes
    do i = 1, num_nodes
        call draw_node(i)
    end do
    
    ! Swap buffers
    call glutSwapBuffers()
    
end subroutine display

subroutine reshape(width, height) bind(C)
    use OpenGL
    implicit none
    integer(GLint), intent(in), value :: width, height
    
    call glViewport(0, 0, width, height)
    call glutPostRedisplay()
    
end subroutine reshape

subroutine mouse_callback(button, state, x, y) bind(C)
    use OpenGL
    use node_gui_data
    implicit none
    integer(GLint), intent(in), value :: button, state, x, y
    integer :: i
    real :: node_x, node_y
    
    last_mouse_x = x
    last_mouse_y = y
    
    if (button == GLUT_LEFT_BUTTON) then
        if (state == GLUT_DOWN) then
            mouse_pressed = .true.
            
            ! Convert screen coordinates to world coordinates
            node_x = (real(x) / zoom_level) - pan_x
            node_y = (real(y) / zoom_level) - pan_y
            
            ! Check if any node was clicked
            do i = 1, num_nodes
                if (node_x >= nodes(i)%x .and. node_x <= nodes(i)%x + nodes(i)%width .and. &
                    node_y >= nodes(i)%y .and. node_y <= nodes(i)%y + nodes(i)%height) then
                    dragging_node = i
                    nodes(i)%is_dragging = .true.
                    exit
                end if
            end do
            
        else if (state == GLUT_UP) then
            mouse_pressed = .false.
            
            ! Stop dragging all nodes
            do i = 1, num_nodes
                nodes(i)%is_dragging = .false.
            end do
            dragging_node = 0
            
        end if
    end if
    
    call glutPostRedisplay()
    
end subroutine mouse_callback

subroutine motion_callback(x, y) bind(C)
    use OpenGL
    use node_gui_data
    implicit none
    integer(GLint), intent(in), value :: x, y
    real :: dx, dy
    
    if (mouse_pressed .and. dragging_node > 0) then
        dx = (real(x - last_mouse_x)) / zoom_level
        dy = (real(y - last_mouse_y)) / zoom_level
        
        nodes(dragging_node)%x = nodes(dragging_node)%x + dx
        nodes(dragging_node)%y = nodes(dragging_node)%y + dy
        
        call glutPostRedisplay()
    end if
    
    last_mouse_x = x
    last_mouse_y = y
    
end subroutine motion_callback

subroutine keyboard_callback(key, x, y) bind(C)
    use OpenGL
    use node_gui_data
    implicit none
    integer(GLubyte), intent(in), value :: key
    integer(GLint), intent(in), value :: x, y
    character :: char_key
    
    char_key = char(key)
    
    select case(char_key)
    case('q', 'Q', char(27))  ! 'q', 'Q', or ESC to quit
        stop
        
    case('+', '=')  ! Zoom in
        zoom_level = zoom_level * 1.1
        call glutPostRedisplay()
        
    case('-', '_')  ! Zoom out
        zoom_level = zoom_level / 1.1
        call glutPostRedisplay()
        
    case('r', 'R')  ! Reset view
        zoom_level = 1.0
        pan_x = 0.0
        pan_y = 0.0
        call glutPostRedisplay()
        
    end select
    
end subroutine keyboard_callback

subroutine special_callback(key, x, y) bind(C)
    use OpenGL
    use node_gui_data
    implicit none
    integer(GLint), intent(in), value :: key, x, y
    real, parameter :: pan_speed = 10.0
    
    select case(key)
    case(GLUT_KEY_LEFT)
        pan_x = pan_x + pan_speed
        call glutPostRedisplay()
        
    case(GLUT_KEY_RIGHT)
        pan_x = pan_x - pan_speed
        call glutPostRedisplay()
        
    case(GLUT_KEY_UP)
        pan_y = pan_y + pan_speed
        call glutPostRedisplay()
        
    case(GLUT_KEY_DOWN)
        pan_y = pan_y - pan_speed
        call glutPostRedisplay()
        
    end select
    
end subroutine special_callback

! Main program
program node_gui_opengl
    use OpenGL
    use node_gui_data
    implicit none
    
    integer :: argc = 1
    character(len=32) :: argv = 'node_gui'
    
    ! Declare external callback functions
    external :: display, reshape, mouse_callback, motion_callback
    external :: keyboard_callback, special_callback
    
    ! Initialize nodes
    call initialize_nodes()
    
    ! Initialize GLUT
    call glutInit(argc, loc(argv))
    call glutInitDisplayMode(GLUT_DOUBLE + GLUT_RGB + GLUT_DEPTH)
    call glutInitWindowSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    call glutInitWindowPosition(100, 100)
    
    ! Create window
    if (glutCreateWindow('Node-based Image Processing - OpenGL') == 0) then
        write(*,*) 'Error creating window'
        stop
    end if
    
    ! Set callback functions
    call glutDisplayFunc(display)
    call glutReshapeFunc(reshape)
    call glutMouseFunc(mouse_callback)
    call glutMotionFunc(motion_callback)
    call glutKeyboardFunc(keyboard_callback)
    call glutSpecialFunc(special_callback)
    
    ! Enable depth testing
    call glEnable(GL_DEPTH_TEST)
    call glDepthFunc(GL_LEQUAL)
    
    ! Set clear color (dark background)
    call glClearColor(0.15, 0.15, 0.2, 1.0)
    
    ! Enable blending for smooth lines
    call glEnable(GL_BLEND)
    call glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    call glEnable(GL_LINE_SMOOTH)
    call glHint(GL_LINE_SMOOTH_HINT, GL_NICEST)
    
    ! Start the main loop
    call glutMainLoop()
    
end program node_gui_opengl