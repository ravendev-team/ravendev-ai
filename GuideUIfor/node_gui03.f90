! OpenGL Node-based GUI in Fortran using GLUT and OpenGL
! Compile with: g95 -o node_gui.exe node_gui.f90 opengl.f90 -lopengl32 -lglu32 -lfreeglut

!---------------------------------------------------------------
! Made by : ravendev ( dwfree74@naver.com / elca6659@gmail.com)
!           https://github.com/ravendev-team/ravendev-ai
!---------------------------------------------------------------

! 이 버전의 수정 사항:
! - 클릭 간에 connect_mode 유지(동일 이벤트에서 자동 취소 없음)
! - 입력 포트 hit 테스트 강화(더 큰 hit박스 + 디버그 로그)
! - 메뉴 + 확대/축소/이동 + 드래그 + 동적 연결을 포함한 명확하고 간단한 예시
!
module node_gui_data
    use iso_c_binding
    implicit none
    integer, parameter :: WINDOW_WIDTH  = 1000
    integer, parameter :: WINDOW_HEIGHT = 600

    integer, parameter :: MAX_NODES = 32
    integer, parameter :: MAX_CONNS = 128

    ! Menu constants
    integer, parameter :: MENU_RESET_VIEW  = 1
    integer, parameter :: MENU_CLEAR_CONNS = 2
    integer, parameter :: MENU_QUIT        = 3

    type :: node_type
        real :: x, y
        real :: width, height
        integer :: node_id
        character(len=64) :: title
        logical :: is_dragging
        real :: color_r, color_g, color_b
        character(len=200) :: image_path
        integer :: texture_id
    end type node_type

    type :: connection_type
        integer :: from_node  ! node index (output port)
        integer :: to_node    ! node index (input port)
        logical :: active
    end type connection_type

    type(node_type) :: nodes(MAX_NODES)
    integer :: num_nodes = 0

    type(connection_type) :: connections(MAX_CONNS)
    integer :: num_conns = 0

    integer :: dragging_node = 0
    logical :: mouse_pressed = .false.
    logical :: pan_pressed = .false.
    integer :: last_mouse_x = 0, last_mouse_y = 0

    real :: zoom_level = 1.0
    real :: pan_x = 0.0, pan_y = 0.0

    ! Connection creation state
    logical :: connect_mode = .false.
    integer :: connect_from = 0  ! node index for output port when starting a connection
contains
    pure logical function point_in_rect(px, py, rx, ry, rw, rh)
        real, intent(in) :: px, py, rx, ry, rw, rh
        point_in_rect = (px >= rx .and. px <= rx + rw .and. py >= ry .and. py <= ry + rh)
    end function point_in_rect

    pure subroutine get_port_rect(idx, is_input, rx, ry, rw, rh)
        integer, intent(in) :: idx
        logical, intent(in) :: is_input
        real, intent(out) :: rx, ry, rw, rh
        real :: port_size, port_y
        ! Enlarge hitbox for easier clicking
        port_size = 16.0
        ! y increases downward due to glOrtho(..., top=height, bottom=0)
        port_y = nodes(idx)%y + nodes(idx)%height - 20.0
        rw = port_size
        rh = port_size
        if (is_input) then
            rx = nodes(idx)%x - port_size/2.0
        else
            rx = nodes(idx)%x + nodes(idx)%width - port_size/2.0
        end if
        ry = port_y - (port_size-10.0)/2.0   ! center vertically
    end subroutine get_port_rect
end module node_gui_data

module gl_helpers
    use node_gui_data
    implicit none
contains
    subroutine draw_text(x, y, s)
        use OpenGL
        implicit none
        real, intent(in) :: x, y
        character(len=*), intent(in) :: s
        integer :: i, n
        character(len=1) :: c

        call glRasterPos2f(x, y)
        n = len_trim(s)
        do i = 1, n
            c = s(i:i)
            call glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, iachar(c))
        end do
    end subroutine draw_text
end module gl_helpers

! ---------------------- Initialization ----------------------
subroutine initialize_nodes()
    use node_gui_data
    implicit none
    integer :: i

    num_nodes = 6
    dragging_node = 0
    mouse_pressed = .false.
    pan_pressed = .false.
    connect_mode = .false.
    connect_from = 0

    do i = 1, MAX_CONNS
        connections(i)%active = .false.
        connections(i)%from_node = 0
        connections(i)%to_node = 0
    end do
    num_conns = 0

    nodes(1)%x = 60.0;  nodes(1)%y = 60.0
    nodes(1)%width = 180.0; nodes(1)%height = 110.0
    nodes(1)%node_id = 1; nodes(1)%title = 'Original Image'
    nodes(1)%is_dragging = .false.; nodes(1)%color_r = 0.45; nodes(1)%color_g = 0.65; nodes(1)%color_b = 1.0

    nodes(2)%x = 300.0; nodes(2)%y = 60.0
    nodes(2)%width = 180.0; nodes(2)%height = 110.0
    nodes(2)%node_id = 2; nodes(2)%title = 'Step01'
    nodes(2)%is_dragging = .false.; nodes(2)%color_r = 0.8; nodes(2)%color_g = 0.1; nodes(2)%color_b = 0.2

    nodes(3)%x = 540.0; nodes(3)%y = 60.0
    nodes(3)%width = 180.0; nodes(3)%height = 110.0
    nodes(3)%node_id = 3; nodes(3)%title = 'Step02'
    nodes(3)%is_dragging = .false.; nodes(3)%color_r = 1.0; nodes(3)%color_g = 0.5; nodes(3)%color_b = 0.0

    nodes(4)%x = 300.0; nodes(4)%y = 230.0
    nodes(4)%width = 180.0; nodes(4)%height = 110.0
    nodes(4)%node_id = 4; nodes(4)%title = 'Step03'
    nodes(4)%is_dragging = .false.; nodes(4)%color_r = 0.2; nodes(4)%color_g = 0.8; nodes(4)%color_b = 0.2

    nodes(5)%x = 540.0; nodes(5)%y = 230.0
    nodes(5)%width = 180.0; nodes(5)%height = 110.0
    nodes(5)%node_id = 5; nodes(5)%title = 'Step04'
    nodes(5)%is_dragging = .false.; nodes(5)%color_r = 0.5; nodes(5)%color_g = 0.2; nodes(5)%color_b = 0.8

    nodes(6)%x = 780.0; nodes(6)%y = 230.0
    nodes(6)%width = 180.0; nodes(6)%height = 110.0
    nodes(6)%node_id = 6; nodes(6)%title = 'Step05'
    nodes(6)%is_dragging = .false.; nodes(6)%color_r = 0.9; nodes(6)%color_g = 0.1; nodes(6)%color_b = 0.6
end subroutine initialize_nodes

! ---------------------- Drawing ----------------------
subroutine draw_grid()
    use OpenGL
    implicit none
    integer :: i
    real, parameter :: grid_size = 20.0
    integer, parameter :: grid_lines = 80

    call glColor3f(0.22, 0.22, 0.27)
    call glBegin(GL_LINES)
    do i = 0, grid_lines
        call glVertex2f(real(i)*grid_size, 0.0)
        call glVertex2f(real(i)*grid_size, real(grid_lines)*grid_size)
    end do
    do i = 0, grid_lines
        call glVertex2f(0.0, real(i)*grid_size)
        call glVertex2f(real(grid_lines)*grid_size, real(i)*grid_size)
    end do
    call glEnd()
end subroutine draw_grid

subroutine draw_ports(node_idx)
    use OpenGL
    use node_gui_data
    implicit none
    integer, intent(in) :: node_idx
    real :: port_size, input_x, output_x, port_y
    port_size = 10.0
    input_x = nodes(node_idx)%x - port_size/2.0
    output_x = nodes(node_idx)%x + nodes(node_idx)%width - port_size/2.0
    port_y = nodes(node_idx)%y + nodes(node_idx)%height - 20.0

    ! input (blue) for nodes beyond first
    if (nodes(node_idx)%node_id > 1) then
        call glColor3f(0.3, 0.6, 1.0)
        call glBegin(GL_QUADS)
        call glVertex2f(input_x, port_y)
        call glVertex2f(input_x+port_size, port_y)
        call glVertex2f(input_x+port_size, port_y+port_size)
        call glVertex2f(input_x, port_y+port_size)
        call glEnd()
    end if

    ! output (orange) for every node
    call glColor3f(1.0, 0.6, 0.2)
    call glBegin(GL_QUADS)
    call glVertex2f(output_x, port_y)
    call glVertex2f(output_x+port_size, port_y)
    call glVertex2f(output_x+port_size, port_y+port_size)
    call glVertex2f(output_x, port_y+port_size)
    call glEnd()
end subroutine draw_ports

subroutine bezier_point(p0x,p0y,p1x,p1y,p2x,p2y,p3x,p3y,t,x,y)
    implicit none
    real, intent(in) :: p0x,p0y,p1x,p1y,p2x,p2y,p3x,p3y,t
    real, intent(out) :: x,y
    real :: u, tt, uu, uuu, ttt
    u=1.0-t; tt=t*t; uu=u*u; uuu=uu*u; ttt=tt*t
    x = uuu*p0x + 3.0*uu*t*p1x + 3.0*u*tt*p2x + ttt*p3x
    y = uuu*p0y + 3.0*uu*t*p1y + 3.0*u*tt*p2y + ttt*p3y
end subroutine bezier_point

subroutine draw_bezier_line(node1_idx, node2_idx)
    use OpenGL
    use node_gui_data
    implicit none
    integer, intent(in) :: node1_idx, node2_idx
    real :: start_x,start_y,end_x,end_y,ctrl1_x,ctrl1_y,ctrl2_x,ctrl2_y
    real :: t,x,y
    integer :: i, segments
    segments = 24

    start_x = nodes(node1_idx)%x + nodes(node1_idx)%width
    start_y = nodes(node1_idx)%y + nodes(node1_idx)%height - 20.0 + 5.0
    end_x   = nodes(node2_idx)%x
    end_y   = nodes(node2_idx)%y + nodes(node2_idx)%height - 20.0 + 5.0

    ctrl1_x = start_x + 60.0; ctrl1_y = start_y
    ctrl2_x = end_x - 60.0;   ctrl2_y = end_y

    call glBegin(GL_LINE_STRIP)
    do i = 0, segments
        t = real(i)/real(segments)
        call bezier_point(start_x,start_y,ctrl1_x,ctrl1_y,ctrl2_x,ctrl2_y,end_x,end_y,t,x,y)
        call glVertex2f(x,y)
    end do
    call glEnd()
end subroutine draw_bezier_line

subroutine draw_connections()
    use OpenGL
    use node_gui_data
    implicit none
    integer :: i
    call glLineWidth(3.0)
    call glColor3f(1.0, 1.0, 0.3)
    do i = 1, num_conns
        if (connections(i)%active) then
            call draw_bezier_line(connections(i)%from_node, connections(i)%to_node)
        end if
    end do
end subroutine draw_connections

subroutine draw_node(node_idx)
    use OpenGL
    use node_gui_data
    use gl_helpers
    implicit none
    integer, intent(in) :: node_idx
    real :: x1,y1,x2,y2,brightness

    x1 = nodes(node_idx)%x; y1 = nodes(node_idx)%y
    x2 = nodes(node_idx)%x + nodes(node_idx)%width
    y2 = nodes(node_idx)%y + nodes(node_idx)%height

    brightness = 1.0
    if (nodes(node_idx)%is_dragging) brightness = 1.25

    ! background gradient (top bright -> bottom dark)
    call glBegin(GL_QUADS)
    call glColor3f(nodes(node_idx)%color_r*brightness, nodes(node_idx)%color_g*brightness, nodes(node_idx)%color_b*brightness)
    call glVertex2f(x1,y1); call glVertex2f(x2,y1)
    call glColor3f(nodes(node_idx)%color_r*0.7, nodes(node_idx)%color_g*0.7, nodes(node_idx)%color_b*0.7)
    call glVertex2f(x2,y2); call glVertex2f(x1,y2)
    call glEnd()

    ! border
    call glColor3f(0.85,0.85,0.92)
    call glLineWidth(2.0)
    call glBegin(GL_LINE_LOOP)
    call glVertex2f(x1,y1); call glVertex2f(x2,y1); call glVertex2f(x2,y2); call glVertex2f(x1,y2)
    call glEnd()

    ! title background strip
    call glColor3f(0.1, 0.1, 0.1)
    call glBegin(GL_QUADS)
    call glVertex2f(x1+4, y1+4); call glVertex2f(x2-4, y1+4)
    call glVertex2f(x2-4, y1+22); call glVertex2f(x1+4, y1+22)
    call glEnd()

    ! title text
    call glColor3f(1.0,1.0,1.0)
    call draw_text(x1+8.0, y1+18.0, trim(nodes(node_idx)%title))

    ! ports
    call draw_ports(node_idx)
end subroutine draw_node

! ---------------------- Connection Management ----------------------
subroutine add_connection(from_idx, to_idx)
    use node_gui_data
    implicit none
    integer, intent(in) :: from_idx, to_idx
    integer :: i

    if (from_idx <= 0 .or. to_idx <= 0) return
    if (from_idx == to_idx) return

    ! Ensure not duplicated
    do i = 1, num_conns
        if (connections(i)%active) then
            if (connections(i)%from_node == from_idx .and. connections(i)%to_node == to_idx) return
        end if
    end do

    if (num_conns < MAX_CONNS) then
        num_conns = num_conns + 1
        connections(num_conns)%from_node = from_idx
        connections(num_conns)%to_node = to_idx
        connections(num_conns)%active = .true.
        write(*,*) 'Connection added: ', from_idx, ' -> ', to_idx
    else
        write(*,*) 'Max connections reached.'
    end if
end subroutine add_connection

subroutine clear_connections()
    use node_gui_data
    implicit none
    integer :: i
    do i = 1, num_conns
        connections(i)%active = .false.
    end do
    num_conns = 0
    write(*,*) 'All connections cleared.'
end subroutine clear_connections

! ---------------------- GLUT Callbacks ----------------------
subroutine display() bind(C)
    use OpenGL
    use node_gui_data
    implicit none
    integer :: i

    call glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

    call glMatrixMode(GL_PROJECTION)
    call glLoadIdentity()
    call glOrtho(0.0d0, dble(WINDOW_WIDTH), dble(WINDOW_HEIGHT), 0.0d0, -1.0d0, 1.0d0)

    call glMatrixMode(GL_MODELVIEW)
    call glLoadIdentity()

    call glScalef(zoom_level, zoom_level, 1.0)
    call glTranslatef(pan_x, pan_y, 0.0)

    call draw_grid()
    call draw_connections()

    do i = 1, num_nodes
        call draw_node(i)
    end do

    call glutSwapBuffers()
end subroutine display

subroutine reshape(width, height) bind(C)
    use OpenGL
    implicit none
    integer(GLint), intent(in), value :: width, height
    call glViewport(0, 0, width, height)
    call glutPostRedisplay()
end subroutine reshape

subroutine keyboard_callback(key, x, y) bind(C)
    use OpenGL
    use node_gui_data
    implicit none
    integer(GLubyte), intent(in), value :: key
    integer(GLint), intent(in), value :: x, y
    character :: char_key
    char_key = char(key)

    select case(char_key)
    case('q','Q', char(27))
        stop
    case('+','=' )
        zoom_level = zoom_level * 1.1
        call glutPostRedisplay()
    case('-','_' )
        zoom_level = zoom_level / 1.1
        call glutPostRedisplay()
    case('r','R')
        zoom_level = 1.0; pan_x = 0.0; pan_y = 0.0
        call glutPostRedisplay()
    case('c','C')
        call clear_connections()
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
    case(GLUT_KEY_LEFT);  pan_x = pan_x + pan_speed
    case(GLUT_KEY_RIGHT); pan_x = pan_x - pan_speed
    case(GLUT_KEY_UP);    pan_y = pan_y + pan_speed
    case(GLUT_KEY_DOWN);  pan_y = pan_y - pan_speed
    end select
    call glutPostRedisplay()
end subroutine special_callback

subroutine mouse_callback(button, state, x, y) bind(C)
    use OpenGL
    use node_gui_data
    implicit none
    integer(GLint), intent(in), value :: button, state, x, y
    integer :: i
    real :: wx, wy
    real :: rx, ry, rw, rh
    logical :: hit

    last_mouse_x = x; last_mouse_y = y

    ! Convert to world coordinates (y grows downward)
    wx = (real(x) / zoom_level) - pan_x
    wy = (real(y) / zoom_level) - pan_y

    if (state == GLUT_DOWN) then
        select case (button)
        case (GLUT_LEFT_BUTTON)
            mouse_pressed = .true.

            if (.not. connect_mode) then
                ! 1) Start connect mode if output port clicked
                do i = 1, num_nodes
                    call get_port_rect(i, .false., rx, ry, rw, rh)  ! output port
                    hit = point_in_rect(wx, wy, rx, ry, rw, rh)
                    if (hit) then
                        connect_mode = .true.
                        connect_from = i
                        write(*,*) 'Connect mode: from node ', i, ' (mouse=', wx, wy, ')'
                        call glutPostRedisplay()
                        return  ! ⭐ Do NOT cancel here; wait for next click
                    end if
                end do

                ! If not connecting, try to start dragging node
                do i = 1, num_nodes
                    if (point_in_rect(wx, wy, nodes(i)%x, nodes(i)%y, nodes(i)%width, nodes(i)%height)) then
                        dragging_node = i
                        nodes(i)%is_dragging = .true.
                        exit
                    end if
                end do
            else
                ! 2) We are in connect_mode: finalize if input port clicked
                do i = 1, num_nodes
                    if (nodes(i)%node_id > 1) then
                        call get_port_rect(i, .true., rx, ry, rw, rh)  ! input port
                        write(*,*) 'Check input node ', i, ' rect=(', rx, ry, rw, rh, ') mouse=(', wx, wy, ')'
                        hit = point_in_rect(wx, wy, rx, ry, rw, rh)
                        if (hit) then
                            call add_connection(connect_from, i)
                            connect_mode = .false.
                            connect_from = 0
                            call glutPostRedisplay()
                            return
                        end if
                    end if
                end do
                ! 2b) Clicked elsewhere: cancel connect mode
                write(*,*) 'Connect mode cancelled (clicked empty).'
                connect_mode = .false.
                connect_from = 0
            end if

        case (GLUT_MIDDLE_BUTTON)
            pan_pressed = .true.

        case (3)  ! wheel up (FreeGLUT)
            zoom_level = zoom_level * 1.1
            call glutPostRedisplay()
        case (4)  ! wheel down
            zoom_level = zoom_level / 1.1
            call glutPostRedisplay()
        end select

    else if (state == GLUT_UP) then
        select case (button)
        case (GLUT_LEFT_BUTTON)
            mouse_pressed = .false.
            if (dragging_node > 0) then
                nodes(dragging_node)%is_dragging = .false.
                dragging_node = 0
            end if
        case (GLUT_MIDDLE_BUTTON)
            pan_pressed = .false.
        end select
    end if
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
    else if (pan_pressed) then
        dx = (real(x - last_mouse_x)) / zoom_level
        dy = (real(y - last_mouse_y)) / zoom_level
        pan_x = pan_x + dx
        pan_y = pan_y + dy
        call glutPostRedisplay()
    end if

    last_mouse_x = x; last_mouse_y = y
end subroutine motion_callback

! ---------------------- Menus ----------------------
subroutine menu_handler(value) bind(C)
    use OpenGL
    use node_gui_data
    use iso_c_binding
    implicit none
    integer(c_int), value :: value

    select case (value)
    case (MENU_RESET_VIEW)
        zoom_level = 1.0; pan_x = 0.0; pan_y = 0.0
        call glutPostRedisplay()
    case (MENU_CLEAR_CONNS)
        call clear_connections()
        call glutPostRedisplay()
    case (MENU_QUIT)
        stop
    end select
end subroutine menu_handler

subroutine create_glut_menu()
    use OpenGL
    use node_gui_data
    use iso_c_binding
    implicit none
    integer(c_int) :: menu_id
    external :: menu_handler   ! declare callback procedure

    menu_id = glutCreateMenu(menu_handler)
    call glutAddMenuEntry('Reset View (R)', MENU_RESET_VIEW)
    call glutAddMenuEntry('Clear Connections (C)', MENU_CLEAR_CONNS)
    call glutAddMenuEntry('Quit (Q)', MENU_QUIT)
    call glutAttachMenu(GLUT_RIGHT_BUTTON)
end subroutine create_glut_menu

! ---------------------- Main ----------------------
program node_gui_opengl
    use OpenGL
    use node_gui_data
    implicit none
    integer :: argc
    character(len=32) :: argv

    external :: display, reshape, mouse_callback, motion_callback
    external :: keyboard_callback, special_callback
    external :: menu_handler

    call initialize_nodes()

    argc = 1
    argv = 'node_gui'//char(0)

    call glutInit(argc, loc(argv))
    call glutInitDisplayMode(GLUT_DOUBLE + GLUT_RGB + GLUT_DEPTH)
    call glutInitWindowSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    call glutInitWindowPosition(100, 100)

    if (glutCreateWindow('Node-based Image Processing - OpenGL (Fortran)') == 0) then
        write(*,*) 'Error creating window'
        stop
    end if

    call glutDisplayFunc(display)
    call glutReshapeFunc(reshape)
    call glutMouseFunc(mouse_callback)
    call glutMotionFunc(motion_callback)
    call glutKeyboardFunc(keyboard_callback)
    call glutSpecialFunc(special_callback)

    call glEnable(GL_DEPTH_TEST)
    call glDepthFunc(GL_LEQUAL)
    call glClearColor(0.15, 0.15, 0.20, 1.0)

    call glEnable(GL_BLEND)
    call glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    call glEnable(GL_LINE_SMOOTH)

    call create_glut_menu()

    call glutMainLoop()
end program node_gui_opengl
