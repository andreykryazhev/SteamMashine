unit UnitOpenGL;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OpenGL, ExtCtrls, Math, StdCtrls, Menus;

type
  Tmainform = class(TForm)
    Timer: TTimer;
    pmMain: TPopupMenu;
    pmParameters: TMenuItem;
    pmExit: TMenuItem;
    pmFullScreen: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TimerTimer(Sender: TObject);
    procedure pmParametersClick(Sender: TObject);
    procedure pmExitClick(Sender: TObject);
    procedure pmFullScreenClick(Sender: TObject);
    procedure SetPixelFormatforGL(winDC: HDC);
  private
    { Private declarations }
  public
    winDC: HDC;
    winGL: HGLRC;
    timerId: uint;
    quadCylinder, quadHitch, quadPiston, quadCasing, quadHitch2: GLUQuadricObj;
    zoom, posX, posY, rotateX, rotateY, count: integer;
    wheelX, wheelY, wheelZ, wheelThick: single;
    spokeX, spokeY, spokeZ, spokeThick, spokeLenght : single;
    detallavel, spokeCount: integer;
    rotated, mode, acceleration, switch, light: boolean;
    rotateMachineX, rotateMachineY, rotateMachineZ: integer;
    x, y, newX, newY, x1, y1, CylinderLenght, steps: single;
   // rotateZ: integer;
    spZ: single;
    angVelocity, step, velocityStep: integer;
    lastCount, newCount: longint;
    FPS: word; // количество кадров в секунду
    { Public declarations }
  end;

const radiusBig = 2;
      radiusSmall = 1.5;
      radiusCenter = 0.5;
      maxvelocity = 2500;

type TStepDraw = (sZero, sOne, sTwo, sThree, sFour, sFive, sSix, sSeven, sEight);
type TVelocity = -maxvelocity..maxvelocity;

var
  mainform: Tmainform;
  stepDraw: TStepDraw;
  velocity: TVelocity;
  vertexs: array [0..100] of GLfloat;
  light0: array [0..3] of GLfloat = (0, 0, 10, 0);
  //light1: array [0..3] of GLfloat = (0, 0, -10, 0);

implementation

{$R *.dfm}

uses ParametersUnit, MMSystem;

procedure Tmainform.FormPaint(Sender: TObject);
var i: word;
    radius, alpha, sinFi, Fi, advY: single;
begin
//
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  glColor3f(0.7, 0.1, 0.1);

  if light then
    begin
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0)
    end
  else
    begin
    glDisable(GL_LIGHT0);
    glDisable(GL_LIGHTING);
    end;

  case mode of
    true:
      begin
      glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
      gluQuadricDrawStyle(quadCylinder, GLU_LINE)
      end;
    false:
      begin
      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
      gluQuadricDrawStyle(quadCylinder, GLU_FILL)
      end;
  end;

  glPushMatrix; // A
  glTranslate(wheelX, wheelY, wheelZ);
  glRotate(rotateMachineX, 1, 0, 0);
  glRotate(rotateMachineY, 0, 1, 0);
  glRotate(rotateMachineZ, 0, 0, 1);

  glPushMatrix; // B

  // вращение колеса и шатуна (в соответствии с spZ)
  glRotate(spZ, 0, 0, 1);

    // прорисовка колеса
    glPushMatrix; // C     > x, ^ y, * z

    // верхн¤¤ и нижн¤¤ части, "ободы" колес снаружи, внутри и в центре
    for i:=1 to detallavel do
      begin

      if stepDraw > sZero then begin
      // верх
      x :=  -Pi + i*2*Pi/detallavel + x1;
      y :=  -Pi + i*2*Pi/detallavel + y1;

      glNormal3f(0, 0, 1);
      glColor3f(0.7, 0.1, 0.1);
      glBegin(GL_TRIANGLE_STRIP);
        glVertex3f( radiusBig * cos(x), radiusBig * sin(y), 0 );
        glVertex3f( radiusSmall * cos(x), radiusSmall * sin(y), 0 );
        x :=  x + 2*Pi/detallavel; y := y + 2*Pi/detallavel;
        glVertex3f( radiusBig * cos(x), radiusBig * sin(y), 0 );
        glVertex3f( radiusSmall * cos(x), radiusSmall * sin(y), 0 );
      glEnd;
      end;

      if stepDraw > sOne then begin
      // низ
      x := -Pi + i*2*Pi/detallavel + x1;
      y := -Pi + i*2*Pi/detallavel + y1;

      glNormal3f(0, 0, -1);
      glBegin(GL_TRIANGLE_STRIP);
        glVertex3f( radiusBig * cos(x), radiusBig * sin(y), - wheelThick);
        glVertex3f( radiusSmall * cos(x), radiusSmall * sin(y), - wheelThick);
        x := x + 2*Pi/detallavel; y := y + 2*Pi/detallavel;
        glVertex3f( radiusBig * cos(x), radiusBig * sin(y), - wheelThick);
        glVertex3f( radiusSmall * cos(x), radiusSmall * sin(y), - wheelThick);
      glEnd;
      end;

      if stepDraw > sTwo then begin
      // ободы снаружи
      x := -Pi + i*2*Pi/detallavel + x1;
      y := -Pi + i*2*Pi/detallavel + y1;
      newX := x + 2*Pi/detallavel;
      newY := y + 2*Pi/detallavel;

      glBegin(GL_TRIANGLE_STRIP);
        // ставим нормаль дл¤ возможности применени¤ освещени¤
        // можно так
        // glNormal3f(cos(x), sin(y), 0)
        // но так вроде правильнее
        glNormal3f(cos((newX + x)/2), sin((newY + y)/2), 0);
        glVertex3f( radiusBig * cos(x), radiusBig * sin(y), 0 );
        glVertex3f( radiusBig * cos(x), radiusBig * sin(y), - wheelThick);
        glVertex3f( radiusBig * cos(newX), radiusBig * sin(newY), 0);
        glVertex3f( radiusBig * cos(newX), radiusBig * sin(newY), - wheelThick);
      glEnd;
      end;

      if stepDraw > sThree then begin
      // ободы внутри
      x := -Pi + i*2*Pi/detallavel + x1;
      y := -Pi + i*2*Pi/detallavel  + y1;
      newX := x + 2*Pi/detallavel;
      newY := y + 2*Pi/detallavel;

      glBegin(GL_TRIANGLE_STRIP);
        //glNormal3f(-cos(x), -sin(y), 0);
        glNormal3f(-cos((newX + x)/2), -sin((newY + y)/2), 0);
        glVertex3f( radiusSmall * cos(x), radiusSmall * sin(y), 0 );
        glVertex3f( radiusSmall * cos(x), radiusSmall * sin(y), - wheelThick);
        glVertex3f( radiusSmall * cos(newX), radiusSmall * sin(newY), 0 );
        glVertex3f( radiusSmall * cos(newX), radiusSmall * sin(newY), - wheelThick);
      glEnd;
      end;

      if stepDraw > sFour then begin
      // ободы в центре
      x := -Pi + i*2*Pi/detallavel + x1;
      y := -Pi + i*2*Pi/detallavel + y1;
      newX := x + 2*Pi/detallavel;
      newY := y + 2*Pi/detallavel;

      glBegin(GL_TRIANGLE_STRIP);
        //glNormal3f(cos(x), sin(y), 0);
        glNormal3f(cos((newX + x)/2), sin((newY + y)/2), wheelZ);
        glVertex3f( radiusCenter * cos(x), radiusCenter * sin(y), 0 );
        glVertex3f( radiusCenter * cos(x), radiusCenter * sin(y), - wheelThick);
        glVertex3f( radiusCenter * cos(newX), radiusCenter * sin(newY), 0);
        glVertex3f( radiusCenter * cos(newX), radiusCenter * sin(newY), - wheelThick);
      glEnd;
      end;

      end;

      if stepDraw > sFive then begin
      // верх колеса в центре
      glBegin(GL_TRIANGLE_FAN);
        glNormal3f(0, 0, 1);
        //glVertex3f(wheelX, wheelY, wheelZ);
        for i:=0 to detallavel do
          begin
          x := 2*Pi*i/detallavel  + x1; y := 2*Pi*i/detallavel + y1;
          glVertex3f( radiusCenter * cos(x), radiusCenter * sin(y), 0 )
          end;
      glEnd;
      end;

      if stepDraw > sSix then begin
      // низ колеса в центре
      glBegin(GL_TRIANGLE_FAN);
        glNormal3f(0, 0, -1);
        //glVertex3f(wheelX, wheelY, wheelZ - wheelThick);
        for i:=0 to detallavel do
          begin
          x := 2*Pi*i/detallavel + x1; y := 2*Pi*i/detallavel + y1;
          glVertex3f( radiusCenter * cos(x), radiusCenter * sin(y), - wheelThick )
          end;
      glEnd;
      end;
    //glPopMatrix; !!! }

    if stepDraw > sSeven then begin
    // прорисовка спиц
    //glPushMatrix;
    for i:=1 to spokeCount do
      begin
      glPushMatrix; // D
      //glTranslate(wheelX , wheelY, wheelZ);
      glRotate(i*2*180/spokeCount, 0, 0, 1);
      // верх спицы
      glBegin(GL_POLYGON);
        glNormal3f(0, 0, 1);
        glVertex3f(radiusCenter - 0.05, -spokeThick, 0);
        glVertex3f(radiusCenter - 0.05, spokeThick, 0);
        glVertex3f(radiusCenter + 1 + 0.03, spokeThick, 0);
        glVertex3f(radiusCenter + 1 + 0.03, -spokeThick, 0);
      glEnd;
      // низ спицы
      glBegin(GL_POLYGON);
        glNormal3f(0, 0, -1);
        glVertex3f(radiusCenter - 0.05, -spokeThick, 0 - wheelThick);
        glVertex3f(radiusCenter - 0.05, spokeThick, 0 - wheelThick);
        glVertex3f(radiusCenter + 1 + 0.03, spokeThick, 0 - wheelThick);
        glVertex3f(radiusCenter + 1 + 0.03, -spokeThick, 0 - wheelThick);
      glEnd;
      // перва¤ грань
      glBegin(GL_POLYGON);
        glNormal3f(0, 1, 0);
        glVertex3f(radiusCenter - 0.05, spokeThick, 0);
        glVertex3f(radiusCenter - 0.05, spokeThick, 0 - wheelThick);
        glVertex3f(radiusCenter + 1 + 0.03, spokeThick, 0 - wheelThick);
        glVertex3f(radiusCenter + 1 + 0.03, spokeThick, 0);
      glEnd;
      // втора¤ грань
      glBegin(GL_POLYGON);
        glNormal3f(0, -1, 0);
        glVertex3f(radiusCenter - 0.05, -spokeThick, 0);
        glVertex3f(radiusCenter - 0.05, -spokeThick, 0 - wheelThick);
        glVertex3f(radiusCenter + 1 + 0.03, -spokeThick, 0 - wheelThick);
        glVertex3f(radiusCenter + 1 + 0.03, -spokeThick, 0);
      glEnd;
      glPopMatrix; // D
      end;
    end;

    glPopMatrix; // C

glPopMatrix; // B

    if stepDraw = sEight then begin
    // прорисовка шатуна и его сцепки с колесом, а также цилиндра
    // считаем нужные нам углы, чтобы шатун был как будто прив¤зан к оси Y
    radius := (radiusBig + radiusSmall)/5;
    sinFi := radius * sin((90+spZ)*Pi/180) / spokeLenght;
    Fi := arccos(sinFi);
    Fi := Fi*180/Pi;                    //  –јƒ»”— ¬–јў≈Ќ»я (radius)
    alpha := 90 - Fi;                   //  ___-----===/
                                        //  |spZ+90   / альфа
                                        //  |        /
    // начинаем рисовать                //  |       /
    glPushMatrix; // E                  //  |      /
      glRotate(spZ, 0, 0, 1);           //  |     / ƒЋ»Ќј
      glTranslate(radius, 0, 0.2);      //  |    /  Ўј“”Ќј
                                        //  |   /   (spokeLenght)
                                        //  |  /
                                        //  | /
                                        //  |/
                                        //  / фи
     // прорисовка сцепки
     glPushMatrix; // F
       glTranslate(0, 0, -0.2);
       gluCylinder(quadHitch, 0.05, 0.05, 0.35, 8, 1);
     glPopMatrix;  // F 

     //glPushMatrix;
      // прорисовка шатуна
      glRotate(90, 1, 0, 0);
      glRotate(-spZ, 0, 1, 0); // сначал шатун ставим строго вертикально
      glRotate(-alpha, 0, 1, 0); // затем поворачиваем на угол "альфа"
      glColor3f(1, 1, 1);
      gluCylinder(quadCylinder, 0.1, 0.1, spokeLenght, detallavel div 2, 1);

      // прорисовка поршн¤
      glTranslate(0, 0, spokeLenght);
      glRotate(alpha, 0, 1, 0);
      glColor3f(0, 0, 1);
      gluCylinder(quadPiston, 0.5, 0.5, cylinderLenght, detallavel, 1);
      glRotate(90, 0, 0, 1);
        // верхн¤¤ крышка поршн¤ (нижней нет - еЄ всЄ равно не видно)
        glBegin(GL_TRIANGLE_FAN);
          glNormal3f(0, 0, -1);     //
          //glVertex3f(wheelX, wheelY, wheelZ);
          for i:=0 to detallavel do
            begin
            x := 2*Pi*i/detallavel; y := 2*Pi*i/detallavel;
            glVertex3f( 0.5 * cos(x), 0.5 * sin(y), 0)
            end;
        glEnd;

    glPopMatrix; // E - конец прорисовки шатуна и сцепки
    end;

    // прорисовка подставки, "станины" и 2-й сцепки
    glPushMatrix;
    advY := -((radiusBig + radiusSmall)/5 + spokeLenght + cylinderLenght);

    glColor3f(1, 1, 1);
    // прорисовка сцепки колеса со "станиной"
    glPushMatrix;
      glTranslate(0, 0, -0.7);
      gluCylinder(quadHitch2, 0.3, 0.3, 0.2, detallavel, 1);
    glPopMatrix;

    // прорисовка "станины"
    glBegin(GL_POLYGON);
      glNormal3f(0, 0, 1);
      glVertex3f(-1, advY, -0.7);
      glVertex3f(-1, 0.5, -0.7);
      glVertex3f(1, 0.5, -0.7);
      glVertex3f(1, advY, -0.7);
    glEnd;
    glBegin(GL_POLYGON);
      glNormal3f(-1, 0, 0);
      glVertex3f(-1, advY, -0.7);
      glVertex3f(-1, 0.5, -0.7);
      glVertex3f(-1, 0.5, -1.5);
      glVertex3f(-1, advY, -1.5);
    glEnd;
    glBegin(GL_POLYGON);
      glNormal3f(0, 0, -1);
      glVertex3f(-1, advY, -1.5);
      glVertex3f(-1, 0.5, -1.5);
      glVertex3f(1, 0.5, -1.5);
      glVertex3f(1, advY, -1.5);
    glEnd;
    glBegin(GL_POLYGON);
      glNormal3f(1, 0, 0);
      glVertex3f(1, advY, -0.7);
      glVertex3f(1, 0.5, -0.7);
      glVertex3f(1, 0.5, -1.5);
      glVertex3f(1, advY, -1.5);
    glEnd;
    glBegin(GL_POLYGON);
      glNormal3f(0, 1, 0);
      glVertex3f(-1, 0.5, -0.7);
      glVertex3f(-1, 0.5, -1.5);
      glVertex3f(1, 0.5, -1.5);
      glVertex3f(1, 0.5, -0.7);  
    glEnd;

    glDisable(GL_LIGHTING);
    // прорисовка подставки
    glTranslate(0, advY, 0.2);
    glBegin(GL_POLYGON);
      glNormal3f(0, 1, 0);
      glColor3f(0.0, 1, 1);
      glVertex3f(-3, 0, 3);
      glVertex3f(-3, 0, -3);
      glVertex3f(3, 0, -3);
      glVertex3f(3, 0, 3);
    glEnd;

    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    // прорисовка оболочки поршн¤
    glColor3f(0.5, 0.5, 0.5);
    glRotate(270, 1, 0, 0);
    gluCylinder(quadCasing, 0.515, 0.515, 2.5, detallavel, 1);
    
    glPopMatrix;
  glPopMatrix; // A

  SwapBuffers(winDC);

  {inc(FPS);
  newCount := GetTickCount;
  if newCount - lastCount > 1000 then
    begin
    lbFPS.Caption := 'FPS  ' + inttostr(FPS);
    lastCount := newCount;
    FPS := 0
    end;}

end;

procedure Tmainform.FormCreate(Sender: TObject);
var style: longint;
begin

  light := false;
  velocity := 0; velocityStep := 100; angVelocity := 0;
  lastCount := 0; FPS := 0;
  stepdraw := sEight; switch := false;
  zoom := 30; mode := true; spZ := -90;
  spokeCount := 8; spokeThick := 0.1{*2}; spokeLenght := 4;
  cylinderLenght := 1; detallavel := 25;
  wheelX := 0; wheelY := 0; wheelZ := 0; wheelThick := 0.5;

  winDC := GetDC(handle);

  SetPixelFormatforGL(winDC);

  winGL := wglCreateContext(winDC);
  wglMakeCurrent(winDC, winGL);

  glClearColor(0, 0, 0, 1);                  

  glEnable(GL_DEPTH_TEST);
  //glEnable(GL_LIGHTING);
  glLightfv(GL_LIGHT0,GL_POSITION, @light0);
  //glLightfv(GL_LIGHT1,GL_POSITION, @light1);
  //glEnable(GL_LIGHT0);
  //glEnable(GL_LIGHT1);

  glEnable(GL_COLOR_MATERIAL);
  //glEnable(GL_AUTO_NORMAL);
  //glEnable(GL_CULL_FACE);

  quadCylinder := gluNewQuadric;
  quadHitch := gluNewQuadric;
  quadHitch2 := gluNewQuadric;
  quadPiston := gluNewQuadric;
  quadCasing := gluNewQuadric;
  //glGetintegerv(GL_MAX_LIGHTS, @count);
  Caption := 'Welcome to the "Steam Machine". Press ''s'' (start) for launching, and ''+'' and ''-'' for velocity control'
end;

procedure Tmainform.SetPixelFormatforGL;
var pfd: TPixelFormatDescriptor;
    PixelFormat: integer;
begin
  FillChar(pfd, sizeof(pfd), 0);
  pfd.dwFlags := PFD_DOUBLEBUFFER or PFD_DRAW_TO_WINDOW or
    PFD_SUPPORT_OPENGL or PFD_GENERIC_FORMAT or PFD_SWAP_COPY;
  PixelFormat := ChoosePixelFormat(winDC, @pfd);
  SetPixelFormat(winDC, PixelFormat, @pfd);
end;

procedure Tmainform.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  gluDeleteQuadric(quadCylinder);
  wglMakeCurrent(0, 0);
  wglDeleteContext(winGL);
  ReleaseDC(handle, winDC);
  DeleteDC(winDC)
end;


procedure Tmainform.FormResize(Sender: TObject);
begin
  glViewPort(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
 // gluLookAt(4, 0, 0, 0, 0, 0, 0, 0, 1);
  //glOrtho(-1, 1, -1, -1, 1, 7);
  //glFrustum(-1, 1, -1, 1, 1, 7);
  gluPerspective(zoom*3, ClientWidth/ClientHeight, 1, 15);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glTranslate(0, 0, -8);

  InvalidateRect(handle, nil, false)
end;

procedure Tmainform.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  rotated := true; posX := X; posY := Y
end;

procedure Tmainform.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  rotated := false
end;

procedure Tmainform.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if rotated then
    begin
    glRotate(X - posX, 0, 1, 0);
    glRotate(Y - posY, 1, 0, 0);
    rotateX := X -posX; rotateY := Y - posY;
    posX := X; posY := Y;
    InvalidateRect(handle, nil, false)
    end;
end;

procedure Tmainform.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  dec(zoom);
  FormResize(mainform)
end;

procedure Tmainform.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  inc(zoom);
  FormResize(mainform)
end;

procedure Tmainform.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: close;
    VK_LEFT: wheelX := wheelX - 0.1;
    VK_RIGHT: wheelX := wheelX + 0.1;
    VK_DOWN: wheelY := wheelY - 0.1;
    VK_UP: wheelY := wheelY + 0.1;
    VK_SPACE: mode := not mode;
    VK_RETURN: begin x1 := x1 + 1; y1 := y1 + 1 end;
    76: light := not light; // свет вкл/выкл
    191:
      begin
      if stepDraw = sEight then stepDraw := sZero
      else inc(stepDraw)
      end;
    187: if Timer.Enabled then
           begin
           if velocity < maxvelocity then
           velocity := velocity + 50;
           if step < velocity then acceleration := true;
           end
         else Key := ord(#0);
    189: if Timer.Enabled then
           begin
           if velocity > -maxvelocity then
           velocity := velocity - 50;
           if step > velocity then acceleration := false
           end
           else Key := ord(#0);
    83: begin
        switch := not switch; // —тарт/—топ
        if switch then Timer.Enabled := true
        end;
    88: rotateMachineX := rotateMachineX + 2;
    89: rotateMachineY := rotateMachineY + 2;
    90: rotateMachineZ := rotateMachineZ + 2;
  end;
  InvalidateRect(handle, nil, false)
end;


procedure Tmainform.TimerTimer(Sender: TObject);
var StepByStep {пока от монитора не ослеп} : byte;
    str: string[5];
    oldspZ, res: single;
begin

  // "откючение" двигател¤, движение на "выбеге"
  if not switch then
    begin
    velocity := 0;
    if step < velocity then acceleration := true;
    if step > velocity then acceleration := false;
    end;

  // ставим скорости ускорени¤/замедлени¤ и "выбега"  
  case switch  of
    true: begin StepByStep := 1; str := 'On' end;
    false: begin StepByStep := 5; str := 'Off' end;
  end;

  // ускоренное или замедленное движение
  case acceleration of
    true: if step < velocity then step := step + StepByStep;
    false: if step > velocity then step := step - StepByStep;
  end;
  if not switch then
    if (abs(step) - velocity < StepByStep) then
      begin
      Timer.Enabled := false;
      step := 0
      end;

  oldspZ := spZ;
  spZ := spZ + step/velocityStep;
  res := spZ - oldspZ;

  if abs(spZ) >= 36000 then spZ := 0;

  Caption := 'Task on velocity: ' + inttostr(velocity) + '  spZ ' +
    floattostr(round(spZ)) + '  step ' + floattostr(step) +
    '  Angular velocity: ' + floattostrf((50*res)/360, ffGeneral, 2, 2) +
    ' r/sek    Engine state: ' + str;
  InvalidateRect(handle, nil, false);
end;

procedure Tmainform.pmParametersClick(Sender: TObject);
begin
  parametersform.ShowModal
end;

procedure Tmainform.pmExitClick(Sender: TObject);
begin
  Close
end;

procedure Tmainform.pmFullScreenClick(Sender: TObject);
begin
  if pmFullScreen.Checked then
    begin
    WindowState := wsMaximized;
    BorderStyle := bsNone
    end
  else
    begin
    WindowState := wsNormal;
    BorderStyle := bsSizeable
    end;

  winDC := GetDC(handle);
  SetPixelFormatforGL(winDC);
  //winGL := wglCreateContext(winDC);
  wglMakeCurrent(winDC, winGL);
  FormResize(nil);
  InvalidateRect(handle, nil, false);


end;



end.
