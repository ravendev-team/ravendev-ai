! Modified OpenGL Node-based GUI in Fortran with Fixed BMP Image Display
! Compile with: gfortran -o node_gui03.exe node_gui03_modified.f90 -lopengl32 -lglu32 -lfreeglut

!---------------------------------------------------------------
! Made by : ravendev ( dwfree74@naver.com / elca6659@gmail.com)
!           https://github.com/ravendev-team/ravendev-ai
!---------------------------------------------------------------

! 이 버전의 수정 사항:
! - 클릭 간에 connect_mode 유지(동일 이벤트에서 자동 취소 없음)
! - 입력 포트 hit 테스트 강화(더 큰 hit박스 + 디버그 로그)
! - 메뉴 + 확대/축소/이동 + 드래그 + 동적 연결을 포함한 명확하고 간단한 예시
!
! 이 버전의 수정 사항:
! - images/input.bmp 보여주기 (해상도가 아직 낮음)
!

module opengl_mod
  use iso_c_binding
  implicit none

  ! OpenGL constants
  integer(c_int), parameter :: GL_TEXTURE_2D = 3553
  integer(c_int), parameter :: GL_RGB = 6407
  integer(c_int), parameter :: GL_UNSIGNED_BYTE = 5121
  integer(c_int), parameter :: GL_COLOR_BUFFER_BIT = 16384
  integer(c_int), parameter :: GL_DEPTH_BUFFER_BIT = 256
  integer(c_int), parameter :: GL_QUADS = 7
  integer(c_int), parameter :: GL_LINES = 1
  integer(c_int), parameter :: GL_LINE_STRIP = 3
  integer(c_int), parameter :: GL_TEXTURE_MIN_FILTER = 10241
  integer(c_int), parameter :: GL_TEXTURE_MAG_FILTER = 10240
  integer(c_int), parameter :: GL_LINEAR = 9729
  integer(c_int), parameter :: GL_NEAREST = 9728
  integer(c_int), parameter :: GL_TEXTURE_WRAP_S = 10242
  integer(c_int), parameter :: GL_TEXTURE_WRAP_T = 10243
  integer(c_int), parameter :: GL_CLAMP = 10496
  integer(c_int), parameter :: GL_REPEAT = 10497
  integer(c_int), parameter :: GL_PROJECTION = 5889
  integer(c_int), parameter :: GL_MODELVIEW = 5888
  integer(c_int), parameter :: GL_DEPTH_TEST = 2929
  integer(c_int), parameter :: GL_LEQUAL = 515
  integer(c_int), parameter :: GL_BLEND = 3042
  integer(c_int), parameter :: GL_SRC_ALPHA = 770
  integer(c_int), parameter :: GL_ONE_MINUS_SRC_ALPHA = 771
  integer(c_int), parameter :: GL_TEXTURE_ENV = 8960
  integer(c_int), parameter :: GL_TEXTURE_ENV_MODE = 8704
  integer(c_int), parameter :: GL_REPLACE = 7681
  integer(c_int), parameter :: GL_ENABLE_BIT = 8192
  integer(c_int), parameter :: GL_LINE_SMOOTH = 2848

  ! GLUT constants
  integer(c_int), parameter :: GLUT_RGB = 0
  integer(c_int), parameter :: GLUT_DOUBLE = 2
  integer(c_int), parameter :: GLUT_SINGLE = 0
  integer(c_int), parameter :: GLUT_DEPTH = 16
  integer(c_int), parameter :: GLUT_DOWN = 0
  integer(c_int), parameter :: GLUT_UP = 1
  integer(c_int), parameter :: GLUT_LEFT_BUTTON = 0
  integer(c_int), parameter :: GLUT_MIDDLE_BUTTON = 1
  integer(c_int), parameter :: GLUT_RIGHT_BUTTON = 2
  integer(c_int), parameter :: GLUT_KEY_LEFT = 100
  integer(c_int), parameter :: GLUT_KEY_UP = 101
  integer(c_int), parameter :: GLUT_KEY_RIGHT = 102
  integer(c_int), parameter :: GLUT_KEY_DOWN = 103
  integer(c_int), parameter :: GLUT_BITMAP_HELVETICA_12 = 6

  ! OpenGL/GLUT interfaces
  interface
    subroutine glGenTextures(n, textures) bind(c, name="glGenTextures")
      use iso_c_binding
      integer(c_int), value :: n
      integer(c_int) :: textures(*)
    end subroutine

    subroutine glBindTexture(target, texture) bind(c, name="glBindTexture")
      use iso_c_binding
      integer(c_int), value :: target, texture
    end subroutine

    subroutine glTexImage2D(target, level, internalformat, width, height, border, format, type, data) bind(c, name="glTexImage2D")
      use iso_c_binding
      integer(c_int), value :: target, level, internalformat, width, height, border, format, type
      integer :: data(*)
    end subroutine

    subroutine glTexParameteri(target, pname, param) bind(c, name="glTexParameteri")
      use iso_c_binding
      integer(c_int), value :: target, pname, param
    end subroutine

    subroutine glClear(mask) bind(c, name="glClear")
      use iso_c_binding
      integer(c_int), value :: mask
    end subroutine

    subroutine glClearColor(red, green, blue, alpha) bind(c, name="glClearColor")
      use iso_c_binding
      real(c_float), value :: red, green, blue, alpha
    end subroutine

    subroutine glEnable(cap) bind(c, name="glEnable")
      use iso_c_binding
      integer(c_int), value :: cap
    end subroutine

    subroutine glDisable(cap) bind(c, name="glDisable")
      use iso_c_binding
      integer(c_int), value :: cap
    end subroutine

    subroutine glBegin(mode) bind(c, name="glBegin")
      use iso_c_binding
      integer(c_int), value :: mode
    end subroutine

    subroutine glEnd() bind(c, name="glEnd")
      use iso_c_binding
    end subroutine

    subroutine glTexCoord2f(s, t) bind(c, name="glTexCoord2f")
      use iso_c_binding
      real(c_float), value :: s, t
    end subroutine

    subroutine glVertex2f(x, y) bind(c, name="glVertex2f")
      use iso_c_binding
      real(c_float), value :: x, y
    end subroutine

    subroutine glOrtho(left, right, bottom, top, near, far) bind(c, name="glOrtho")
      use iso_c_binding
      real(c_double), value :: left, right, bottom, top, near, far
    end subroutine

    subroutine glViewport(x, y, width, height) bind(c, name="glViewport")
      use iso_c_binding
      integer(c_int), value :: x, y, width, height
    end subroutine

    subroutine glMatrixMode(mode) bind(c, name="glMatrixMode")
      use iso_c_binding
      integer(c_int), value :: mode
    end subroutine

    subroutine glLoadIdentity() bind(c, name="glLoadIdentity")
      use iso_c_binding
    end subroutine

    subroutine glColor3f(red, green, blue) bind(c, name="glColor3f")
      use iso_c_binding
      real(c_float), value :: red, green, blue
    end subroutine

    subroutine glScalef(x, y, z) bind(c, name="glScalef")
      use iso_c_binding
      real(c_float), value :: x, y, z
    end subroutine

    subroutine glTranslatef(x, y, z) bind(c, name="glTranslatef")
      use iso_c_binding
      real(c_float), value :: x, y, z
    end subroutine

    subroutine glLineWidth(width) bind(c, name="glLineWidth")
      use iso_c_binding
      real(c_float), value :: width
    end subroutine

    subroutine glDepthFunc(func) bind(c, name="glDepthFunc")
      use iso_c_binding
      integer(c_int), value :: func
    end subroutine

    subroutine glBlendFunc(sfactor, dfactor) bind(c, name="glBlendFunc")
      use iso_c_binding
      integer(c_int), value :: sfactor, dfactor
    end subroutine

    subroutine glRasterPos2f(x, y) bind(c, name="glRasterPos2f")
      use iso_c_binding
      real(c_float), value :: x, y
    end subroutine

    subroutine glutInit(argc, argv) bind(c, name="glutInit")
      use iso_c_binding
      integer(c_int) :: argc
      type(c_ptr) :: argv
    end subroutine

    subroutine glutInitDisplayMode(mode) bind(c, name="glutInitDisplayMode")
      use iso_c_binding
      integer(c_int), value :: mode
    end subroutine

    subroutine glutInitWindowSize(width, height) bind(c, name="glutInitWindowSize")
      use iso_c_binding
      integer(c_int), value :: width, height
    end subroutine

    subroutine glutInitWindowPosition(x, y) bind(c, name="glutInitWindowPosition")
      use iso_c_binding
      integer(c_int), value :: x, y
    end subroutine

    integer(c_int) function glutCreateWindow(title) bind(c, name="glutCreateWindow")
      use iso_c_binding
      character(c_char) :: title(*)
    end function

    subroutine glutDisplayFunc(callback) bind(c, name="glutDisplayFunc")
      use iso_c_binding
      type(c_funptr), value :: callback
    end subroutine

    subroutine glutReshapeFunc(callback) bind(c, name="glutReshapeFunc")
      use iso_c_binding
      type(c_funptr), value :: callback
    end subroutine

    subroutine glutKeyboardFunc(callback) bind(c, name="glutKeyboardFunc")
      use iso_c_binding
      type(c_funptr), value :: callback
    end subroutine

    subroutine glutSpecialFunc(callback) bind(c, name="glutSpecialFunc")
      use iso_c_binding
      type(c_funptr), value :: callback
    end subroutine

    subroutine glutMouseFunc(callback) bind(c, name="glutMouseFunc")
      use iso_c_binding
      type(c_funptr), value :: callback
    end subroutine

    subroutine glutMotionFunc(callback) bind(c, name="glutMotionFunc")
      use iso_c_binding
      type(c_funptr), value :: callback
    end subroutine

    subroutine glutPostRedisplay() bind(c, name="glutPostRedisplay")
      use iso_c_binding
    end subroutine

    subroutine glutMainLoop() bind(c, name="glutMainLoop")
      use iso_c_binding
    end subroutine

    subroutine glutSwapBuffers() bind(c, name="glutSwapBuffers")
      use iso_c_binding
    end subroutine

    subroutine glutBitmapCharacter(font, character) bind(c, name="glutBitmapCharacter")
      use iso_c_binding
      type(c_ptr), value :: font
      integer(c_int), value :: character
    end subroutine

    integer(c_int) function glutCreateMenu(callback) bind(c, name="glutCreateMenu")
      use iso_c_binding
      type(c_funptr), value :: callback
    end function

    subroutine glutAddMenuEntry(label, value) bind(c, name="glutAddMenuEntry")
      use iso_c_binding
      character(c_char) :: label(*)
      integer(c_int), value :: value
    end subroutine

    subroutine glTexEnvi(target, pname, param) bind(c, name="glTexEnvi")
      use iso_c_binding
      integer(c_int), value :: target, pname, param
    end subroutine

    subroutine glPushAttrib(mask) bind(c, name="glPushAttrib")
      use iso_c_binding
      integer(c_int), value :: mask
    end subroutine

    subroutine glPopAttrib() bind(c, name="glPopAttrib")
      use iso_c_binding
    end subroutine

    subroutine glutAttachMenu(button) bind(c, name="glutAttachMenu")
      use iso_c_binding
      integer(c_int), value :: button
    end subroutine
  end interface

end module opengl_mod

module node_gui_data
    use opengl_mod
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
        integer(c_int) :: texture_id
        integer(c_int) :: img_width, img_height
        integer, allocatable :: bmp_data(:)
        logical :: texture_loaded
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
        port_size = 16.0
        port_y = nodes(idx)%y + nodes(idx)%height - 20.0
        rw = port_size
        rh = port_size
        if (is_input) then
            rx = nodes(idx)%x - port_size/2.0
        else
            rx = nodes(idx)%x + nodes(idx)%width - port_size/2.0
        end if
        ry = port_y - (port_size-10.0)/2.0
    end subroutine get_port_rect

    subroutine load_bmp_image(node_idx)
        integer, intent(in) :: node_idx
        
        ! Variables - copied exactly from working BMP viewer
        character(len=256) :: filename
        integer :: iunit = 10, ios, file_size
        integer(1), allocatable, target :: bmp_data(:)
        integer(1) :: header(54)
        integer :: i, j, temp, data_offset, row_size, padding
        integer :: bits_per_pixel, compression
        integer :: row_start, img_width, img_height
        integer(1) :: dummy
        logical :: file_exists
        integer :: src_i, src_j, src_idx, dst_idx

        ! Initialize
        nodes(node_idx)%texture_loaded = .false.
        filename = trim(nodes(node_idx)%image_path)

        write(*,*) 'Loading BMP file: ', trim(filename)

        ! Check if file exists
        inquire(file=trim(filename), exist=file_exists)
        if (.not. file_exists) then
            write(*,*) 'Error: File does not exist: ', trim(filename)
            return
        end if

        ! Get file size
        inquire(file=trim(filename), size=file_size)
        write(*,*) 'File size: ', file_size, ' bytes'

        ! Open BMP file
        open(unit=iunit, file=trim(filename), form='unformatted', access='stream', status='old', iostat=ios)
        if (ios /= 0) then
            write(*,*) 'Error opening file: ', ios
            return
        end if

        ! Read BMP header
        read(iunit, iostat=ios) header
        if (ios /= 0) then
            write(*,*) 'Error reading header: ', ios
            close(iunit)
            return
        end if

        ! Check BMP signature
        if (header(1) /= ichar('B') .or. header(2) /= ichar('M')) then
            write(*,*) 'Error: Not a valid BMP file'
            close(iunit)
            return
        end if

        ! Extract image information (little-endian) - EXACTLY COPIED FROM WORKING VIEWER
        data_offset = transfer(header(11:14), data_offset)
        img_width = transfer(header(19:22), img_width)
        img_height = transfer(header(23:26), img_height)
        bits_per_pixel = transfer(header(29:30), bits_per_pixel)
        compression = transfer(header(31:34), compression)

        write(*,*) 'Data offset: ', data_offset
        write(*,*) 'Image dimensions: ', img_width, 'x', img_height
        write(*,*) 'Bits per pixel: ', bits_per_pixel
        write(*,*) 'Compression: ', compression

        ! Check format support
        if (bits_per_pixel /= 24) then
            write(*,*) 'Error: Only 24-bit BMP files are supported'
            close(iunit)
            return
        end if

        if (compression /= 0) then
            write(*,*) 'Error: Compressed BMP files are not supported'
            close(iunit)
            return
        end if

        ! Calculate row size (must be multiple of 4 bytes) - EXACTLY COPIED FROM WORKING VIEWER
        row_size = ((img_width * 3 + 3) / 4) * 4
        padding = row_size - (img_width * 3)
        write(*,*) 'Row size: ', row_size, ' bytes, padding: ', padding

        ! Allocate memory for pixel data (no padding in final data) - EXACTLY COPIED FROM WORKING VIEWER
        allocate(bmp_data(img_width * img_height * 3))

        ! Seek to data offset - EXACTLY COPIED FROM WORKING VIEWER
        close(iunit)
        open(unit=iunit, file=trim(filename), form='unformatted', access='stream', status='old')
        
        ! Skip to pixel data - EXACTLY COPIED FROM WORKING VIEWER
        if (data_offset > 54) then
            do i = 1, data_offset - 54
                read(iunit) temp  ! Skip extra header bytes
            end do
        end if

        ! Read pixel data row by row (BMP stores bottom-to-top) - EXACTLY COPIED FROM WORKING VIEWER
        do i = img_height, 1, -1  ! Read from bottom row to top row
            row_start = (i - 1) * img_width * 3 + 1
            read(iunit) bmp_data(row_start:row_start + img_width * 3 - 1)
            
            ! Skip padding bytes
            do j = 1, padding
                read(iunit) dummy
            end do
        end do

        close(iunit)
        write(*,*) 'BMP file loaded successfully'

        ! Convert BGR to RGB - EXACTLY COPIED FROM WORKING VIEWER
        do i = 1, size(bmp_data), 3
            temp = bmp_data(i)      ! Save B
            bmp_data(i) = bmp_data(i+2)    ! B = R
            bmp_data(i+2) = temp           ! R = B (G stays the same)
        end do

        write(*,*) 'BGR to RGB conversion completed'

        ! Debug: Print some pixel values - EXACTLY COPIED FROM WORKING VIEWER
        write(*,*) 'First few pixels (RGB):'
        do i = 1, min(15, size(bmp_data)), 3
            write(*,'(A,I3,A,3I4)') 'Pixel ', (i+2)/3, ': ', int(bmp_data(i)), int(bmp_data(i+1)), int(bmp_data(i+2))
        end do

        ! Now copy to node structure with downsampling
        nodes(node_idx)%img_width = 256
        nodes(node_idx)%img_height = 256
        
        if (allocated(nodes(node_idx)%bmp_data)) then
            deallocate(nodes(node_idx)%bmp_data)
        end if
        allocate(nodes(node_idx)%bmp_data(256 * 256 * 3))

        ! Simple downsampling
        do i = 0, 255
            do j = 0, 255
                src_i = (i * img_height) / 256
                src_j = (j * img_width) / 256
                if (src_i >= img_height) src_i = img_height - 1
                if (src_j >= img_width) src_j = img_width - 1
                
                src_idx = (src_i * img_width + src_j) * 3 + 1
                dst_idx = (i * 256 + j) * 3 + 1
                
                if (src_idx + 2 <= size(bmp_data) .and. dst_idx + 2 <= size(nodes(node_idx)%bmp_data)) then
                    ! Convert signed bytes (-128~127) to unsigned (0~255)
                    nodes(node_idx)%bmp_data(dst_idx) = int(bmp_data(src_idx))
                    if (nodes(node_idx)%bmp_data(dst_idx) < 0) then
                        nodes(node_idx)%bmp_data(dst_idx) = nodes(node_idx)%bmp_data(dst_idx) + 256
                    end if
                    
                    nodes(node_idx)%bmp_data(dst_idx + 1) = int(bmp_data(src_idx + 1))
                    if (nodes(node_idx)%bmp_data(dst_idx + 1) < 0) then
                        nodes(node_idx)%bmp_data(dst_idx + 1) = nodes(node_idx)%bmp_data(dst_idx + 1) + 256
                    end if
                    
                    nodes(node_idx)%bmp_data(dst_idx + 2) = int(bmp_data(src_idx + 2))
                    if (nodes(node_idx)%bmp_data(dst_idx + 2) < 0) then
                        nodes(node_idx)%bmp_data(dst_idx + 2) = nodes(node_idx)%bmp_data(dst_idx + 2) + 256
                    end if
                end if
            end do
        end do

        deallocate(bmp_data)
        nodes(node_idx)%texture_loaded = .true.
        write(*,*) 'Texture created and uploaded'
    end subroutine load_bmp_image
end module node_gui_data

module gl_helpers
    use node_gui_data
    use opengl_mod
    implicit none
contains
    subroutine draw_text(x, y, s)
        real, intent(in) :: x, y
        character(len=*), intent(in) :: s
        ! Skip text rendering to avoid g95 compiler bug
        ! Text will not be displayed but program will work
        return
    end subroutine draw_text
end module gl_helpers

subroutine initialize_nodes_basic()
    use node_gui_data
    use opengl_mod
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

    ! Initialize nodes with BMP image paths - fix the typo in first node
    nodes(1)%x = 60.0;  nodes(1)%y = 60.0
    nodes(1)%width = 180.0; nodes(1)%height = 110.0
    nodes(1)%node_id = 1; nodes(1)%title = 'Original Image'
    nodes(1)%is_dragging = .false.; nodes(1)%color_r = 0.45; nodes(1)%color_g = 0.65; nodes(1)%color_b = 1.0
    nodes(1)%image_path = 'images/input.bmp'  ! Fixed typo: was 'intput.bmp'
    nodes(1)%texture_loaded = .false.

    nodes(2)%x = 300.0; nodes(2)%y = 60.0
    nodes(2)%width = 180.0; nodes(2)%height = 110.0
    nodes(2)%node_id = 2; nodes(2)%title = 'Step01'
    nodes(2)%is_dragging = .false.; nodes(2)%color_r = 0.8; nodes(2)%color_g = 0.1; nodes(2)%color_b = 0.2
    nodes(2)%image_path = 'images/step01.bmp'
    nodes(2)%texture_loaded = .false.

    nodes(3)%x = 540.0; nodes(3)%y = 60.0
    nodes(3)%width = 180.0; nodes(3)%height = 110.0
    nodes(3)%node_id = 3; nodes(3)%title = 'Step02'
    nodes(3)%is_dragging = .false.; nodes(3)%color_r = 1.0; nodes(3)%color_g = 0.5; nodes(3)%color_b = 0.0
    nodes(3)%image_path = 'images/step02.bmp'
    nodes(3)%texture_loaded = .false.

    nodes(4)%x = 300.0; nodes(4)%y = 230.0
    nodes(4)%width = 180.0; nodes(4)%height = 110.0
    nodes(4)%node_id = 4; nodes(4)%title = 'Step03'
    nodes(4)%is_dragging = .false.; nodes(4)%color_r = 0.2; nodes(4)%color_g = 0.8; nodes(4)%color_b = 0.2
    nodes(4)%image_path = 'images/step03.bmp'
    nodes(4)%texture_loaded = .false.

    nodes(5)%x = 540.0; nodes(5)%y = 230.0
    nodes(5)%width = 180.0; nodes(5)%height = 110.0
    nodes(5)%node_id = 5; nodes(5)%title = 'Step04'
    nodes(5)%is_dragging = .false.; nodes(5)%color_r = 0.5; nodes(5)%color_g = 0.2; nodes(5)%color_b = 0.8
    nodes(5)%image_path = 'images/step04.bmp'
    nodes(5)%texture_loaded = .false.

    nodes(6)%x = 780.0; nodes(6)%y = 230.0
    nodes(6)%width = 180.0; nodes(6)%height = 110.0
    nodes(6)%node_id = 6; nodes(6)%title = 'Step05'
    nodes(6)%is_dragging = .false.; nodes(6)%color_r = 0.9; nodes(6)%color_g = 0.1; nodes(6)%color_b = 0.6
    nodes(6)%image_path = 'images/step05.bmp'
    nodes(6)%texture_loaded = .false.
end subroutine initialize_nodes_basic

subroutine initialize_textures()
    use node_gui_data
    use opengl_mod
    implicit none
    integer :: i
    integer(c_int) :: temp_texture(1)

    write(*,*) 'Starting texture initialization...'
    
    ! Load BMP images and create textures for all nodes
    do i = 1, num_nodes
        write(*,*) 'Processing node ', i
        call load_bmp_image(i)
        if (nodes(i)%texture_loaded) then
            write(*,*) 'Creating texture for node ', i
            call glGenTextures(1, temp_texture)
            nodes(i)%texture_id = temp_texture(1)
            write(*,*) 'Generated texture ID: ', nodes(i)%texture_id
            
            call glBindTexture(GL_TEXTURE_2D, nodes(i)%texture_id)
            write(*,*) 'Bound texture, uploading data...'
            
            call glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, nodes(i)%img_width, nodes(i)%img_height, 0, GL_RGB, GL_UNSIGNED_BYTE, &
                              nodes(i)%bmp_data)
            write(*,*) 'Texture data uploaded'
                              
            call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
            call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
            call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
            call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
            write(*,*) 'Texture parameters set for node ', i, ' with ID: ', nodes(i)%texture_id
        else
            write(*,*) 'Failed to load image for node ', i
        end if
    end do
    
    write(*,*) 'Texture initialization complete!'
end subroutine initialize_textures

subroutine draw_grid()
    use opengl_mod
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
    use opengl_mod
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
    use opengl_mod
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
    use opengl_mod
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

subroutine draw_node_image(node_id)
    use opengl_mod
    use node_gui_data
    implicit none
    integer, intent(in) :: node_id
    real :: img_x, img_y, img_w, img_h
    real :: title_height
    integer :: i, j, pixel_idx
    real :: r, g, b, px, py, step_x, step_y
    
    title_height = 25.0  ! Space reserved for title at top
    
    ! Calculate image area (leave space for title and ports)
    img_x = nodes(node_id)%x + 5.0
    img_y = nodes(node_id)%y + title_height
    img_w = nodes(node_id)%width - 10.0
    img_h = nodes(node_id)%height - title_height - 25.0  ! 25 for port area at bottom
    
    if (nodes(node_id)%texture_loaded) then
        ! Draw image using pixel data directly (without texture)
        call glDisable(GL_TEXTURE_2D)
        
        ! Calculate step size for display
        step_x = img_w / real(nodes(node_id)%img_width)
        step_y = img_h / real(nodes(node_id)%img_height)
        
        ! Draw pixels as small rectangles
        do j = 0, nodes(node_id)%img_height - 1
            do i = 0, nodes(node_id)%img_width - 1
                ! Calculate pixel index in the image data
                pixel_idx = (j * nodes(node_id)%img_width + i) * 3 + 1
                
                if (pixel_idx + 2 <= size(nodes(node_id)%bmp_data)) then
                    ! Get RGB values (0-255) and normalize to 0-1
                    r = real(nodes(node_id)%bmp_data(pixel_idx)) / 255.0
                    g = real(nodes(node_id)%bmp_data(pixel_idx + 1)) / 255.0
                    b = real(nodes(node_id)%bmp_data(pixel_idx + 2)) / 255.0
                else
                    ! Default color if out of bounds
                    r = 0.5; g = 0.5; b = 0.5
                end if
                
                ! Set color and draw pixel rectangle
                call glColor3f(r, g, b)
                px = img_x + real(i) * step_x
                py = img_y + real(j) * step_y
                
                call glBegin(GL_QUADS)
                call glVertex2f(px, py)
                call glVertex2f(px + step_x, py)
                call glVertex2f(px + step_x, py + step_y)
                call glVertex2f(px, py + step_y)
                call glEnd()
            end do
        end do
    else
        ! Draw placeholder if no image loaded
        call glColor3f(0.3, 0.3, 0.3)
        call glBegin(GL_QUADS)
        call glVertex2f(img_x, img_y)
        call glVertex2f(img_x + img_w, img_y)
        call glVertex2f(img_x + img_w, img_y + img_h)
        call glVertex2f(img_x, img_y + img_h)
        call glEnd()
        
        ! Draw "No Image" text area
        call glColor3f(0.7, 0.7, 0.7)
        call glBegin(GL_QUADS)
        call glVertex2f(img_x + img_w/4.0, img_y + img_h/2.0 - 10.0)
        call glVertex2f(img_x + 3.0*img_w/4.0, img_y + img_h/2.0 - 10.0)
        call glVertex2f(img_x + 3.0*img_w/4.0, img_y + img_h/2.0 + 10.0)
        call glVertex2f(img_x + img_w/4.0, img_y + img_h/2.0 + 10.0)
        call glEnd()
    end if
end subroutine draw_node_image

subroutine draw_node(node_id)
    use gl_helpers
    use opengl_mod
    use node_gui_data
    implicit none
    integer, intent(in) :: node_id
    real :: x, y
    character(len=50) :: s

    ! Draw node background first
    call glColor3f(nodes(node_id)%color_r, nodes(node_id)%color_g, nodes(node_id)%color_b)
    call glBegin(GL_QUADS)
    call glVertex2f(nodes(node_id)%x, nodes(node_id)%y)
    call glVertex2f(nodes(node_id)%x + nodes(node_id)%width, nodes(node_id)%y)
    call glVertex2f(nodes(node_id)%x + nodes(node_id)%width, nodes(node_id)%y + nodes(node_id)%height)
    call glVertex2f(nodes(node_id)%x, nodes(node_id)%y + nodes(node_id)%height)
    call glEnd()

    ! Draw the BMP image inside the node
    call draw_node_image(node_id)

    ! Draw node title
    call glColor3f(1.0, 1.0, 1.0)  ! White text
    x = nodes(node_id)%x + 5.0
    y = nodes(node_id)%y + 10.0
    s = nodes(node_id)%title
    call draw_text(x, y, s)

    ! Draw ports
    call draw_ports(node_id)
end subroutine draw_node

subroutine add_connection(from_idx, to_idx)
    use node_gui_data
    implicit none
    integer, intent(in) :: from_idx, to_idx
    integer :: i

    if (from_idx <= 0 .or. to_idx <= 0) return
    if (from_idx == to_idx) return

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

subroutine display() bind(c)
    use gl_helpers
    use opengl_mod
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
    use opengl_mod
    implicit none
    integer(c_int), intent(in), value :: width, height
    call glViewport(0, 0, width, height)
    call glutPostRedisplay()
end subroutine reshape

subroutine keyboard_callback(key, x, y) bind(C)
    use opengl_mod
    use node_gui_data
    implicit none
    integer(c_int), intent(in), value :: key
    integer(c_int), intent(in), value :: x, y
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
    use opengl_mod
    use node_gui_data
    implicit none
    integer(c_int), intent(in), value :: key, x, y
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
    use opengl_mod
    use node_gui_data
    implicit none
    integer(c_int), intent(in), value :: button, state, x, y
    integer :: i
    real :: wx, wy
    real :: rx, ry, rw, rh
    logical :: hit

    last_mouse_x = x; last_mouse_y = y

    wx = (real(x) / zoom_level) - pan_x
    wy = (real(y) / zoom_level) - pan_y

    if (state == GLUT_DOWN) then
        select case (button)
        case (GLUT_LEFT_BUTTON)
            mouse_pressed = .true.

            if (.not. connect_mode) then
                do i = 1, num_nodes
                    call get_port_rect(i, .false., rx, ry, rw, rh)
                    hit = point_in_rect(wx, wy, rx, ry, rw, rh)
                    if (hit) then
                        connect_mode = .true.
                        connect_from = i
                        write(*,*) 'Connect mode: from node ', i, ' (mouse=', wx, wy, ')'
                        call glutPostRedisplay()
                        return
                    end if
                end do

                do i = 1, num_nodes
                    if (point_in_rect(wx, wy, nodes(i)%x, nodes(i)%y, nodes(i)%width, nodes(i)%height)) then
                        dragging_node = i
                        nodes(i)%is_dragging = .true.
                        exit
                    end if
                end do
            else
                do i = 1, num_nodes
                    if (nodes(i)%node_id > 1) then
                        call get_port_rect(i, .true., rx, ry, rw, rh)
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
                write(*,*) 'Connect mode cancelled (clicked empty).'
                connect_mode = .false.
                connect_from = 0
            end if

        case (GLUT_MIDDLE_BUTTON)
            pan_pressed = .true.

        case (3)
            zoom_level = zoom_level * 1.1
            call glutPostRedisplay()
        case (4)
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
    use opengl_mod
    use node_gui_data
    implicit none
    integer(c_int), intent(in), value :: x, y
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

subroutine menu_handler(value) bind(C)
    use opengl_mod
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
    use opengl_mod
    use node_gui_data
    use iso_c_binding
    implicit none
    integer(c_int) :: menu_id
    
    ! Interface for menu_handler
    interface
        subroutine menu_handler(value) bind(C)
            use iso_c_binding
            integer(c_int), value :: value
        end subroutine menu_handler
    end interface

    menu_id = glutCreateMenu(c_funloc(menu_handler))
    call glutAddMenuEntry('Reset View (R)' // c_null_char, MENU_RESET_VIEW)
    call glutAddMenuEntry('Clear Connections (C)' // c_null_char, MENU_CLEAR_CONNS)
    call glutAddMenuEntry('Quit (Q)' // c_null_char, MENU_QUIT)
    call glutAttachMenu(GLUT_RIGHT_BUTTON)
end subroutine create_glut_menu

program main
    use opengl_mod
    use node_gui_data
    implicit none
    integer(c_int) :: argc
    type(c_ptr) :: argv
    integer(c_int) :: window

    ! Interface declarations for all callback functions
    interface
        subroutine display() bind(c)
        end subroutine display
        
        subroutine reshape(width, height) bind(c)
            use iso_c_binding
            integer(c_int), intent(in), value :: width, height
        end subroutine reshape
        
        subroutine keyboard_callback(key, x, y) bind(c)
            use iso_c_binding
            integer(c_int), intent(in), value :: key, x, y
        end subroutine keyboard_callback
        
        subroutine special_callback(key, x, y) bind(c)
            use iso_c_binding
            integer(c_int), intent(in), value :: key, x, y
        end subroutine special_callback
        
        subroutine mouse_callback(button, state, x, y) bind(c)
            use iso_c_binding
            integer(c_int), intent(in), value :: button, state, x, y
        end subroutine mouse_callback
        
        subroutine motion_callback(x, y) bind(c)
            use iso_c_binding
            integer(c_int), intent(in), value :: x, y
        end subroutine motion_callback
    end interface

    ! Initialize only the basic node data first (without textures)
    call initialize_nodes_basic()

    argc = 0
    argv = c_null_ptr

    call glutInit(argc, argv)
    call glutInitDisplayMode(GLUT_DOUBLE + GLUT_RGB + GLUT_DEPTH)
    call glutInitWindowSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    call glutInitWindowPosition(100, 100)

    window = glutCreateWindow('Node-based Image Processing - OpenGL (Fortran)' // c_null_char)
    if (window == 0) then
        write(*,*) 'Error creating window'
        stop
    end if

    call glutDisplayFunc(c_funloc(display))
    call glutReshapeFunc(c_funloc(reshape))
    call glutMouseFunc(c_funloc(mouse_callback))
    call glutMotionFunc(c_funloc(motion_callback))
    call glutKeyboardFunc(c_funloc(keyboard_callback))
    call glutSpecialFunc(c_funloc(special_callback))

    call glEnable(GL_DEPTH_TEST)
    call glDepthFunc(GL_LEQUAL)
    call glClearColor(0.15, 0.15, 0.20, 1.0)

    call glEnable(GL_BLEND)
    call glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    call glEnable(GL_LINE_SMOOTH)

    ! Now initialize textures after OpenGL context is ready
    call initialize_textures()

    call create_glut_menu()

    write(*,*) 'Starting OpenGL main loop...'
    call glutMainLoop()
end program main