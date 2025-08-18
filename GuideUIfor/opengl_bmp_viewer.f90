!---------------------------------------------------------------
! Made by : ravendev ( dwfree74@naver.com / elca6659@gmail.com)
!           https://github.com/ravendev-team/ravendev-ai
!---------------------------------------------------------------

module opengl_mod
  use iso_c_binding
  implicit none

  ! OpenGL constants
  integer(c_int), parameter :: GL_TEXTURE_2D = 3553
  integer(c_int), parameter :: GL_RGB = 6407
  integer(c_int), parameter :: GL_UNSIGNED_BYTE = 5121
  integer(c_int), parameter :: GL_COLOR_BUFFER_BIT = 16384
  integer(c_int), parameter :: GL_QUADS = 7
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

  ! GLUT constants
  integer(c_int), parameter :: GLUT_RGB = 0
  integer(c_int), parameter :: GLUT_DOUBLE = 2
  integer(c_int), parameter :: GLUT_SINGLE = 0

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
      type(c_ptr), value :: data
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

    subroutine glutPostRedisplay() bind(c, name="glutPostRedisplay")
      use iso_c_binding
    end subroutine

    subroutine glutMainLoop() bind(c, name="glutMainLoop")
      use iso_c_binding
    end subroutine

    subroutine glutSwapBuffers() bind(c, name="glutSwapBuffers")
      use iso_c_binding
    end subroutine
  end interface

  ! Module variables
  integer(c_int) :: img_width, img_height
  integer(c_int) :: win_width = 800, win_height = 600
  integer(c_int) :: texture_id(1)
  logical :: texture_loaded = .false.

contains

  subroutine display() bind(c)
    real(c_float) :: aspect_img, aspect_win
    real(c_float) :: scale, display_width, display_height
    real(c_float) :: x_offset, y_offset

    call glClear(GL_COLOR_BUFFER_BIT)

    if (.not. texture_loaded) then
      call glutSwapBuffers()
      return
    end if

    ! Calculate aspect ratios and scaling
    aspect_img = real(img_width) / real(img_height)
    aspect_win = real(win_width) / real(win_height)

    if (aspect_img > aspect_win) then
      ! Image is wider than window
      scale = real(win_width) / real(img_width)
      display_width = real(win_width)
      display_height = real(img_height) * scale
      x_offset = 0.0
      y_offset = (real(win_height) - display_height) * 0.5
    else
      ! Image is taller than window
      scale = real(win_height) / real(img_height)
      display_width = real(img_width) * scale
      display_height = real(win_height)
      x_offset = (real(win_width) - display_width) * 0.5
      y_offset = 0.0
    end if

    ! Set up projection matrix
    call glMatrixMode(GL_PROJECTION)
    call glLoadIdentity()
    call glOrtho(0.0d0, real(win_width, c_double), 0.0d0, real(win_height, c_double), -1.0d0, 1.0d0)

    call glMatrixMode(GL_MODELVIEW)
    call glLoadIdentity()

    ! Enable texturing and bind texture
    call glEnable(GL_TEXTURE_2D)
    call glBindTexture(GL_TEXTURE_2D, texture_id(1))
    call glColor3f(1.0, 1.0, 1.0)  ! Ensure white color multiplier

    ! Draw textured quad (flip Y coordinates for BMP)
    call glBegin(GL_QUADS)
    call glTexCoord2f(0.0, 1.0); call glVertex2f(x_offset, y_offset)
    call glTexCoord2f(1.0, 1.0); call glVertex2f(x_offset + display_width, y_offset)
    call glTexCoord2f(1.0, 0.0); call glVertex2f(x_offset + display_width, y_offset + display_height)
    call glTexCoord2f(0.0, 0.0); call glVertex2f(x_offset, y_offset + display_height)
    call glEnd()

    call glDisable(GL_TEXTURE_2D)
    call glutSwapBuffers()
  end subroutine display

  subroutine reshape(width, height) bind(c)
    integer(c_int), value :: width, height
    win_width = width
    win_height = height
    call glViewport(0, 0, width, height)
    call glutPostRedisplay()
  end subroutine reshape

  subroutine keyboard(key, x, y) bind(c)
    integer(c_int), value :: key, x, y
    if (key == 27) then  ! ESC key
      stop
    end if
  end subroutine keyboard

end module opengl_mod

program opengl_bmp_viewer
  use opengl_mod
  implicit none

  ! Variables
  character(len=256) :: filename = "images/input.bmp"
  integer :: iunit = 10, ios, file_size
  integer(1), allocatable, target :: bmp_data(:)
  integer(1) :: header(54)
  integer :: i, j, temp, data_offset, row_size, padding
  integer :: bits_per_pixel, compression
  integer :: row_start
  integer(1) :: dummy
  logical :: file_exists
  integer(c_int) :: argc
  type(c_ptr) :: argv
  integer(c_int) :: window
  type(c_funptr) :: display_func, reshape_func, keyboard_func

  write(*,*) 'Loading BMP file: ', trim(filename)

  ! Check if file exists
  inquire(file=trim(filename), exist=file_exists)
  if (.not. file_exists) then
    write(*,*) 'Error: File does not exist: ', trim(filename)
    stop
  end if

  ! Get file size
  inquire(file=trim(filename), size=file_size)
  write(*,*) 'File size: ', file_size, ' bytes'

  ! Open BMP file
  open(unit=iunit, file=trim(filename), form='unformatted', access='stream', status='old', iostat=ios)
  if (ios /= 0) then
    write(*,*) 'Error opening file: ', ios
    stop
  end if

  ! Read BMP header
  read(iunit, iostat=ios) header
  if (ios /= 0) then
    write(*,*) 'Error reading header: ', ios
    stop
  end if

  ! Check BMP signature
  if (header(1) /= ichar('B') .or. header(2) /= ichar('M')) then
    write(*,*) 'Error: Not a valid BMP file'
    stop
  end if

  ! Extract image information (little-endian)
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
    stop
  end if

  if (compression /= 0) then
    write(*,*) 'Error: Compressed BMP files are not supported'
    stop
  end if

  ! Calculate row size (must be multiple of 4 bytes)
  row_size = ((img_width * 3 + 3) / 4) * 4
  padding = row_size - (img_width * 3)
  write(*,*) 'Row size: ', row_size, ' bytes, padding: ', padding

  ! Allocate memory for pixel data (no padding in final data)
  allocate(bmp_data(img_width * img_height * 3))

  ! Seek to data offset
  close(iunit)
  open(unit=iunit, file=trim(filename), form='unformatted', access='stream', status='old')
  
  ! Skip to pixel data
  if (data_offset > 54) then
    do i = 1, data_offset - 54
      read(iunit) temp  ! Skip extra header bytes
    end do
  end if

  ! Read pixel data row by row (BMP stores bottom-to-top)
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

  ! Convert BGR to RGB
  do i = 1, size(bmp_data), 3
    temp = bmp_data(i)      ! Save B
    bmp_data(i) = bmp_data(i+2)    ! B = R
    bmp_data(i+2) = temp           ! R = B (G stays the same)
  end do

  write(*,*) 'BGR to RGB conversion completed'

  ! Debug: Print some pixel values
  write(*,*) 'First few pixels (RGB):'
  do i = 1, min(15, size(bmp_data)), 3
    write(*,'(A,I3,A,3I4)') 'Pixel ', (i+2)/3, ': ', int(bmp_data(i)), int(bmp_data(i+1)), int(bmp_data(i+2))
  end do

  ! Initialize GLUT
  argc = 0
  argv = c_null_ptr
  call glutInit(argc, argv)
  call glutInitDisplayMode(GLUT_RGB + GLUT_DOUBLE)
  call glutInitWindowSize(win_width, win_height)
  window = glutCreateWindow("BMP Viewer - Press ESC to exit" // c_null_char)

  ! Set up OpenGL
  call glClearColor(0.2, 0.2, 0.2, 1.0)  ! Dark gray background

  ! Generate and set up texture
  call glGenTextures(1, texture_id)
  call glBindTexture(GL_TEXTURE_2D, texture_id(1))
  
  ! Upload texture data
  call glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, img_width, img_height, 0, GL_RGB, GL_UNSIGNED_BYTE, c_loc(bmp_data(1)))
  
  ! Set texture parameters
  call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
  call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)

  texture_loaded = .true.
  write(*,*) 'Texture created and uploaded'

  ! Set up callbacks
  display_func = c_funloc(display)
  reshape_func = c_funloc(reshape)
  keyboard_func = c_funloc(keyboard)
  
  call glutDisplayFunc(display_func)
  call glutReshapeFunc(reshape_func)
  call glutKeyboardFunc(keyboard_func)

  write(*,*) 'Starting OpenGL main loop...'
  call glutMainLoop()

end program opengl_bmp_viewer