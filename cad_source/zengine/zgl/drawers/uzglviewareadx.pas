{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Andrey Zubarev <zamtmn@yandex.ru>) 
}

unit uzglviewareadx;
{$INCLUDE def.inc}
interface
uses
     Windows, Messages, LCLType, LCLProc, SysUtils, Variants,
     Classes, Graphics, Controls, Forms, Dialogs,
     Menus, ActnList, StdCtrls, ExtCtrls, ComCtrls,
     uDxTypes, uD3Dcommon, uDXGI, uD3D11, uD3D11sdklayers,
     uD3Dcompiler, uD3DX11,

     math,
     uzgldrawerdx,
     uzglbackendmanager,uzbgeomtypes,uzbtypes,uzglviewareaabstract,uzglviewareageneral,uzgldrawcontext,uzbtypesbase;
type
  TVertexData = record
    x: _FLOAT;
    y: _FLOAT;
    z: _FLOAT;
    w: _FLOAT;
    clr: D3DCOLORVALUE;
  end;
const
  input_layout: array [0..1] of D3D11_INPUT_ELEMENT_DESC =
  (
    (SemanticName: 'POSITION'; SemanticIndex: 0; Format: DXGI_FORMAT_R32G32B32A32_FLOAT;
     InputSlot: 0; AlignedByteOffset: 0;
     InputSlotClass: D3D11_INPUT_PER_VERTEX_DATA; InstanceDataStepRate: 0),
    (SemanticName: 'COLOR'; SemanticIndex: 0; Format: DXGI_FORMAT_R32G32B32A32_FLOAT;
     InputSlot: 0; AlignedByteOffset: 0 + (SizeOf(_FLOAT) * 4);
     InputSlotClass: D3D11_INPUT_PER_VERTEX_DATA; InstanceDataStepRate: 0)
  );

  vertices: array[0..2] of TVertexData =
  (
    (x:  0.00; y:  1.00; z: 0.0; w: 1.0; clr: (r: 0.75; g: 0.75; b: 0.25; a: 1.0)),
    (x:  0.75; y: -1.00; z: 0.0; w: 1.0; clr: (r: 0.75; g: 0.25; b: 0.75; a: 1.0)),
    (x: -0.75; y: -1.00; z: 0.0; w: 1.0; clr: (r: 0.25; g: 0.75; b: 0.75; a: 1.0))
  );

  strides: UINT = SizeOf(vertices[Low(vertices)]);
  offsets: UINT = 0;

  sShaderCode_Sample_1: AnsiString =
    '// не изменяйте это определение' + sLineBreak +
    'cbuffer cbConst : register ( b0 )' + sLineBreak +
    '{' + sLineBreak +
    '  float4x4 matView;' + sLineBreak +
    '  float4x4 matProjection;' + sLineBreak +
    '  float4x4 matWorld;' + sLineBreak +
    '  float4x4 matResult;' + sLineBreak +
    '  uint dwTimeInterval;' + sLineBreak +
    '  uint dwGetTickCount;' + sLineBreak +
    '};' + sLineBreak +
    '' + sLineBreak +
    'struct VS_OUTPUT' + sLineBreak +
    '{' + sLineBreak +
    '  float4 pos : SV_POSITION;' + sLineBreak +
    '  float4 clr : COLOR0;' + sLineBreak +
    '};' + sLineBreak +
    '' + sLineBreak +
    '// не изменяйте имя функции (VS)' + sLineBreak +
    'VS_OUTPUT VS ( float4 Pos : POSITION, float4 Clr : COLOR )' + sLineBreak +
    '{' + sLineBreak +
    '  VS_OUTPUT output;' + sLineBreak +
    '  ' + sLineBreak +
    '  output.pos = mul ( Pos, matResult );' + sLineBreak +
    '  output.clr = Clr;' + sLineBreak +
    '  ' + sLineBreak +
    '  return output;' + sLineBreak +
    '}' + sLineBreak +
    '' + sLineBreak +
    '// не изменяйте имя функции (PS)' + sLineBreak +
    'float4 PS ( VS_OUTPUT input ) : SV_Target' + sLineBreak +
    '{' + sLineBreak +
    '  return input.clr;' + sLineBreak +
    '}' + sLineBreak +
    '';

  sShaderCode_Sample_2: AnsiString =
    '// не изменяйте это определение' + sLineBreak +
    'cbuffer cbConst : register ( b0 )' + sLineBreak +
    '{' + sLineBreak +
    '  float4x4 matView;' + sLineBreak +
    '  float4x4 matProjection;' + sLineBreak +
    '  float4x4 matWorld;' + sLineBreak +
    '  float4x4 matResult;' + sLineBreak +
    '  uint dwTimeInterval;' + sLineBreak +
    '  uint dwGetTickCount;' + sLineBreak +
    '};' + sLineBreak +
    '' + sLineBreak +
    'struct VS_OUTPUT' + sLineBreak +
    '{' + sLineBreak +
    '  float4 pos : SV_POSITION;' + sLineBreak +
    '  float4 clr : COLOR0;' + sLineBreak +
    '};' + sLineBreak +
    '' + sLineBreak +
    '// не изменяйте имя функции (VS)' + sLineBreak +
    'VS_OUTPUT VS ( float4 Pos : POSITION, float4 Clr : COLOR, uint vId : SV_VertexID )' + sLineBreak +
    '{' + sLineBreak +
    '  VS_OUTPUT output;' + sLineBreak +
    '  float tmp1;' + sLineBreak +
    '  float tmp2;' + sLineBreak +
    '  float tmp3;' + sLineBreak +
    '  float tmp4;' + sLineBreak +
    '  ' + sLineBreak +
    '  tmp1 = ( sin ( ( dwGetTickCount % 4000 ) / 4000.0 * radians(180) ) );' + sLineBreak +
    '  tmp2 = sin ( ( dwGetTickCount % 5000 ) / 5000.0 * radians(360) );' + sLineBreak +
    '  tmp3 = cos ( ( dwGetTickCount % 5000 ) / 5000.0 * radians(360) );' + sLineBreak +
    '  tmp4 = ( (vId + 1) * sin ( ( dwGetTickCount % 2000 ) / 2000.0 * radians(180) ) );' + sLineBreak +
    '  ' + sLineBreak +
    '  output.pos = float4 ( Pos[0], Pos[1] + 1.0 * tmp1, Pos[2], Pos[3] );' + sLineBreak +
    '  output.pos = float4 ( output.pos[0] * tmp3 + output.pos[2] * tmp2, output.pos[1], output.pos[0] * (-tmp2) + output.pos[2] * tmp3, output.pos[3] );' + sLineBreak +
    '  output.pos = mul ( output.pos, matResult );' + sLineBreak +
    '  output.clr = float4 ( Clr[0] - 0.2 * tmp4, Clr[1] - 0.2 * tmp4, Clr[2] - 0.2 * tmp4, Clr[3] );' + sLineBreak +
    '  ' + sLineBreak +
    '  return output;' + sLineBreak +
    '}' + sLineBreak +
    '' + sLineBreak +
    '// не изменяйте имя функции (PS)' + sLineBreak +
    'float4 PS ( VS_OUTPUT input ) : SV_Target' + sLineBreak +
    '{' + sLineBreak +
    '  return input.clr;' + sLineBreak +
    '}' + sLineBreak +
    '';

{$IFDEF FPC}
function IsDebuggerPresent(): BOOL;
  external 'kernel32.dll' name 'IsDebuggerPresent';
{$ENDIF}

type
    TRenderPanel = class(TCustomControl)
      private
        bInitComplete: Boolean;

        dtFrames: TDateTime;
        nFrames: Int64;
        nLastFPS: Double;

        dwTicksOfLastRender: UINT;

        nSelectedMsaa: UINT;

        pCompiledVertexShader: ID3DBlob;
        pCompiledPixelShader: ID3DBlob;

        pDXGIfactory: IDXGIFactory;
        pDXGIoutput: IDXGIOutput;

        pD3Ddevice: ID3D11Device;
        pD3Dcontext: ID3D11DeviceContext;

        pD3Ddebug: ID3D11Debug;

        pSwapChain: IDXGISwapChain;
        pRenderTargetView: ID3D11RenderTargetView;

        pRasterizerState: ID3D11RasterizerState;
        pInputLayout: ID3D11InputLayout;
        pVertexBuffer: ID3D11Buffer;
        pConstantBuffer: ID3D11Buffer;
        pVertexShader: ID3D11VertexShader;
        pPixelShader: ID3D11PixelShader;
      protected
        procedure CreateParams(var params: TCreateParams);  override;
        procedure WndProc(var msg: TMessage);  override;
      public
        constructor Create(AOwner: TComponent);  override;
        destructor Destroy();  override;

        procedure InitShaders(const sCode: AnsiString; out pVS, pPS: ID3DBlob);
        procedure InitDirect3D();
        procedure FinalizeDirect3D();

        procedure ProcessShaderCompilationMessages(var pErrorMsgs: ID3DBlob; hr, hr2: HRESULT);
        procedure SetDebugName(const pObject: ID3D11DeviceChild; const sName: AnsiString);

        procedure Resize();  override;
        procedure Paint();  override;
      end;
    PTOGLWnd = ^TOGLWnd;
    TOGLWnd = class({TPanel}{TOpenGLControl}TRenderPanel)
    private
    public
      wa:TAbstractViewArea;
      procedure EraseBackground(DC: HDC);{$IFNDEF DELPHI}override;{$ENDIF}
    end;
    TDX11ViewArea=class(TGeneralViewArea)
                      public
                      OpenGLWindow:TOGLWnd;
                      OpenGLParam:TDXData;
                      function CreateWorkArea(TheOwner: TComponent):TCADControl; override;
                      procedure CreateDrawer; override;
                      procedure SetupWorkArea; override;
                      procedure WaResize(sender:tobject); override;

                      procedure SwapBuffers(var DC:TDrawContext); override;
                      procedure LightOn(var DC:TDrawContext); override;
                      procedure LightOff(var DC:TDrawContext); override;
                      procedure DrawGrid(var DC:TDrawContext); override;
                      procedure getareacaps; override;
                      procedure GDBActivateGLContext; override;
                      function NeedDrawInsidePaintEvent:boolean; override;
                      procedure setdeicevariable; override;
                      function getParam:pointer; override;
                      function getParamTypeName:GDBString; override;
                      function CreateRC(_maxdetail:GDBBoolean=false):TDrawContext;override;
                  end;
implementation

type
TConstantBufferData = record
  matView: D3DXMATRIX;
  matProjection: D3DXMATRIX;
  matWorld: D3DXMATRIX;
  matResult: D3DXMATRIX;
  dwTimeInterval: UINT;
  dwGetTickCount: UINT;
  dwUnused: array[2..15] of UINT;
end;

constructor TRenderPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  bInitComplete := FALSE;

  DoubleBuffered := FALSE;
  ControlStyle := [csCaptureMouse, csClickEvents, csDoubleClicks, csMenuEvents, csOpaque{, csOverrideStylePaint}];

  dtFrames := Now();
  nFrames := 0;
  nLastFPS := 0;

  dwTicksOfLastRender := GetTickCount();

  nSelectedMsaa := 1;

  pPixelShader := nil;
  pVertexShader := nil;
  pConstantBuffer := nil;
  pVertexBuffer := nil;
  pInputLayout := nil;
  pRasterizerState := nil;
  pRenderTargetView := nil;
  pSwapChain := nil;
  pD3Ddebug := nil;
  pD3Dcontext := nil;
  pD3Ddevice := nil;
  pDXGIoutput := nil;
  pDXGIfactory := nil;
end;

destructor TRenderPanel.Destroy;
begin
  FinalizeDirect3D();

  inherited Destroy();
end;

procedure TRenderPanel.CreateParams(var params: TCreateParams);
begin
  inherited CreateParams(params);

  params.WindowClass.style := params.WindowClass.style or CS_HREDRAW or CS_VREDRAW;
  params.Style := params.Style or WS_CLIPSIBLINGS or WS_CLIPCHILDREN;
end;

procedure TRenderPanel.WndProc(var msg: TMessage);
begin
  if ( msg.Msg = WM_ERASEBKGND ) and ( bInitComplete ) then
  begin
    msg.Result := 1;
    Exit;
  end;

  inherited WndProc(msg);
end;

procedure TRenderPanel.ProcessShaderCompilationMessages(var pErrorMsgs: ID3DBlob; hr, hr2: HRESULT);
var
  nSize: SIZE_T;
  pData: Pointer;
  sData: AnsiString;
begin
  if ( pErrorMsgs = nil ) then Exit;

  nSize := pErrorMsgs.GetBufferSize();
  pData := pErrorMsgs.GetBufferPointer();

  if ( nSize = 0 ) then
  begin
    pErrorMsgs := nil;
    Exit;
  end;

  SetLength(sData, nSize);
  CopyMemory(PAnsiChar(sData), pData, nSize);
  pErrorMsgs := nil;

  //TFormMain(Owner).txtShaderErrors.Lines.Text := TFormMain(Owner).txtShaderErrors.Lines.Text + sLineBreak + string(sData);
  //TFormMain(Owner).StatusBar.Panels[0].Text := 'Обнаружены ошибки при компиляции шейдера!';
end;

procedure TRenderPanel.SetDebugName(const pObject: ID3D11DeviceChild; const sName: AnsiString);
begin
  if ( pObject <> nil ) and ( Length(sName) > 0 ) then
    pObject.SetPrivateData(WKPDID_D3DDebugObjectName, Length(sName), PAnsiChar(sName))
end;

procedure TRenderPanel.InitShaders(const sCode: AnsiString; out pVS, pPS: ID3DBlob);
var
  hr, hr2: HRESULT;
  pErrorMsgs: ID3DBlob;
begin
  pVS := nil;
  pPS := nil;

  //TFormMain(Owner).txtShaderErrors.Lines.Text := '';

  if ( Length(sCode) = 0 ) then Exit;

  //TFormMain(Owner).StatusBar.Panels[0].Text := '';

  hr2 := S_OK;
  hr := D3DX11CompileFromMemory
        (
          PAnsiChar(sCode), Length(sCode),
          nil, nil, nil, 'VS', 'vs_4_0',
          D3DCOMPILE_ENABLE_STRICTNESS or D3DCOMPILE_WARNINGS_ARE_ERRORS, 0,
          nil, pVS, @pErrorMsgs, @hr2
        );
  ProcessShaderCompilationMessages(pErrorMsgs, hr, hr2);

  hr := D3DX11CompileFromMemory
        (
          PAnsiChar(sCode), Length(sCode),
          nil, nil, nil, 'PS', 'ps_4_0',
          D3DCOMPILE_ENABLE_STRICTNESS or D3DCOMPILE_WARNINGS_ARE_ERRORS, 0,
          nil, pPS, @pErrorMsgs, @hr2
        );
  ProcessShaderCompilationMessages(pErrorMsgs, hr, hr2);

  //if ( pVS <> nil ) and ( pPS <> nil ) and
  //   ( Length(TFormMain(Owner).StatusBar.Panels[0].Text) = 0 ) then
  //  TFormMain(Owner).StatusBar.Panels[0].Text := 'Компиляция шейдеров выполнена успешно';
end;

procedure TRenderPanel.InitDirect3D();
var
  hr: HRESULT;
  nQualityTest: UINT;
  FeatureLevel: D3D11_FEATURE_LEVEL;
  FeatureLevelRet: D3D11_FEATURE_LEVEL;
  vpDesc: D3D11_VIEWPORT;
  pBackBuffer: ID3D11Texture2D;
  srData: D3D11_SUBRESOURCE_DATA;
  cbBuf: TConstantBufferData;
begin
  FinalizeDirect3D();

  hr := CreateDXGIFactory(IDXGIFactory, pDXGIfactory);
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  FeatureLevel := D3D11_FEATURE_LEVEL(0);
  FeatureLevelRet := D3D11_FEATURE_LEVEL(0);

  hr := D3D11CreateDevice
        (
          nil, D3D11_DRIVER_TYPE_HARDWARE, 0,
          IfThen({TFormMain(Owner).actOtherDebugDevice.Checked}false, D3D11_CREATE_DEVICE_DEBUG, 0),
          nil, 0, D3D11_SDK_VERSION,
          nil, @FeatureLevel, nil
        );
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  hr := D3D11CreateDeviceAndSwapChain
        (
          nil, D3D11_DRIVER_TYPE_HARDWARE, 0,
          IfThen({TFormMain(Owner).actOtherDebugDevice.Checked}false, D3D11_CREATE_DEVICE_DEBUG, 0),
          @FeatureLevel, 1, D3D11_SDK_VERSION,
          DXGI_SwapChainDesc
          (
            DXGI_ModeDesc
            (
              Self.ClientWidth, Self.ClientHeight,
              DXGI_Rational_(60, 1),
              DXGI_FORMAT_R8G8B8A8_UNORM,
              DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED,
              DXGI_MODE_SCALING_UNSPECIFIED
            ),
            DXGI_SampleDesc(nSelectedMsaa, 0),
            Self.Handle, TRUE, 1,
            DXGI_USAGE_RENDER_TARGET_OUTPUT,
            DXGI_SWAP_EFFECT_DISCARD,
            0
          ),
          @pSwapChain, @pD3Ddevice, @FeatureLevelRet, @pD3Dcontext
        );
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  SetDebugName(pD3Dcontext, 'TFormMain.pD3Dcontext');

  if ( {TFormMain(Owner).actOtherDebugDevice.Checked}false ) then
  begin
    hr := pD3Ddevice.QueryInterface(ID3D11Debug, pD3Ddebug);
    if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));
  end;

  hr := pSwapChain.GetContainingOutput(pDXGIoutput);
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  hr := pDXGIfactory.MakeWindowAssociation(Self.Handle, DXGI_MWA_NO_WINDOW_CHANGES);
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  hr := pSwapChain.GetBuffer(0, ID3D11Texture2D, pBackBuffer);
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  SetDebugName(pBackBuffer, 'FormMain.pBackBuffer');

  hr := pD3DDevice.CreateRenderTargetView(pBackBuffer, nil, pRenderTargetView);
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  SetDebugName(pRenderTargetView, 'FormMain.pRenderTargetView');

  pD3Dcontext.OMSetRenderTargets(1, @pRenderTargetView, nil);

  vpDesc.Width := Self.ClientWidth;
  vpDesc.Height := Self.ClientHeight;
  vpDesc.MinDepth := 0.0;
  vpDesc.MaxDepth := 1.0;
  vpDesc.TopLeftX := 0;
  vpDesc.TopLeftY := 0;
  pD3DContext.RSSetViewports(1, @vpDesc);

  hr := pD3Ddevice.CreateRasterizerState
        (
          D3D11_RasterizerDesc
          (
            D3D11_FILL_SOLID, D3D11_CULL_NONE,
            FALSE, 0, 0, 0,
            FALSE, FALSE, TRUE, TRUE
          ),
          pRasterizerState
        );
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  SetDebugName(pRasterizerState, 'FormMain.pRasterizerState');

  pD3Dcontext.RSSetState(pRasterizerState);

  ZeroMemory(@cbBuf, SizeOf(cbBuf));
  cbBuf.dwTimeInterval := 0;
  cbBuf.dwGetTickCount := GetTickCount();

  srData.pSysMem := @cbBuf;
  srData.SysMemPitch := 0;
  srData.SysMemSlicePitch := 0;

  hr := pD3Ddevice.CreateBuffer
        (
          D3D11_BufferDesc
          (
            SizeOf(cbBuf),
            D3D11_BIND_CONSTANT_BUFFER,
            D3D11_USAGE_DYNAMIC,
            D3D11_CPU_ACCESS_WRITE,
            0, 0
          ),
          @srData,
          pConstantBuffer
        );
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  SetDebugName(pConstantBuffer, 'TFormMain.pConstantBuffer');

  hr := pD3DDevice.CreateVertexShader
        (
          pCompiledVertexShader.GetBufferPointer(),
          pCompiledVertexShader.GetBufferSize(),
          nil,
          pVertexShader
        );
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  SetDebugName(pVertexShader, 'TFormMain.pVertexShader');

  hr := pD3Ddevice.CreatePixelShader
        (
          pCompiledPixelShader.GetBufferPointer(),
          pCompiledPixelShader.GetBufferSize(),
          nil,
          pPixelShader
        );
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  SetDebugName(pPixelShader, 'TFormMain.pPixelShader');

  hr := pD3Ddevice.CreateInputLayout
        (
          @input_layout[Low(input_layout)], Length(input_layout),
          pCompiledVertexShader.GetBufferPointer(),
          pCompiledVertexShader.GetBufferSize(),
          pInputLayout
        );
  if ( Failed(hr) ) then EOSError.Create(SysErrorMessage(hr));

  SetDebugName(pInputLayout, 'TFormMain.pInputLayout');

  srData.pSysMem := @vertices[Low(vertices)];
  srData.SysMemPitch := 0;
  srData.SysMemSlicePitch := 0;

  hr := pD3Ddevice.CreateBuffer
        (
          D3D11_BufferDesc
          (
            SizeOf(vertices[Low(vertices)]) * Length(vertices),
            D3D11_BIND_VERTEX_BUFFER,
            D3D11_USAGE_DEFAULT,
            0, 0, 0
          ),
          @srData,
          pVertexBuffer
        );
  if ( Failed(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

  SetDebugName(pVertexBuffer, 'TFormMain.pVertexBuffer');

  nQualityTest := 0;
  hr := pD3Ddevice.CheckMultisampleQualityLevels(DXGI_FORMAT_R8G8B8A8_UNORM, 2, nQualityTest);
  //TFormMain(Owner).actRenderMsaa2.Enabled := ( Succeeded(hr) ) and ( nQualityTest > 0 );

  nQualityTest := 0;
  hr := pD3Ddevice.CheckMultisampleQualityLevels(DXGI_FORMAT_R8G8B8A8_UNORM, 4, nQualityTest);
  //TFormMain(Owner).actRenderMsaa4.Enabled := ( Succeeded(hr) ) and ( nQualityTest > 0 );

  nQualityTest := 0;
  hr := pD3Ddevice.CheckMultisampleQualityLevels(DXGI_FORMAT_R8G8B8A8_UNORM, 8, nQualityTest);
  //TFormMain(Owner).actRenderMsaa8.Enabled := ( Succeeded(hr) ) and ( nQualityTest > 0 );

  bInitComplete := TRUE;
end;

procedure TRenderPanel.FinalizeDirect3D();
begin
  bInitComplete := FALSE;

  if ( pD3Dcontext <> nil ) then
    pD3Dcontext.ClearState();

  pPixelShader := nil;
  pVertexShader := nil;
  pConstantBuffer := nil;
  pVertexBuffer := nil;
  pInputLayout := nil;
  pRasterizerState := nil;
  pRenderTargetView := nil;
  pSwapChain := nil;
  pD3Ddebug := nil;
  pD3Dcontext := nil;
  pD3Ddevice := nil;
  pDXGIoutput := nil;
  pDXGIfactory := nil;
end;

procedure TRenderPanel.Resize();
var
  hr: HRESULT;
  swDesc: DXGI_SWAP_CHAIN_DESC;
  vpDesc: D3D11_VIEWPORT;
  pBackBuffer: ID3D11Texture2D;
begin
  try
    if ( not bInitComplete ) then Exit;

    bInitComplete := FALSE;

    pD3Dcontext.OMSetRenderTargets(0, nil, nil);
    pRenderTargetView := nil;

    ZeroMemory(@swDesc, SizeOf(swDesc));
    swDesc.BufferDesc.Format := DXGI_FORMAT_UNKNOWN;

    hr := pSwapChain.GetDesc(swDesc);
    if ( FAILED(hr) ) then raise EOSError.Create(SysErrorMessage(hr));

    if ( nSelectedMsaa = swDesc.SampleDesc.Count ) then
    begin
      hr := pSwapChain.ResizeBuffers
            (
              1,
              Self.ClientWidth, Self.ClientHeight,
              swDesc.BufferDesc.Format, 0
            );

      if ( Failed(hr) ) then
      begin
        //TFormMain(Owner).StatusBar.Panels[0].Text := 'ошибка метода pSwapChain.ResizeBuffers(): ' + QuotedStr(SysErrorMessage(hr));
        Exit;
      end;
    end
    else begin
      pSwapChain := nil;

      hr := pDXGIfactory.CreateSwapChain
            (
              pD3DDevice,
              DXGI_SwapChainDesc
              (
                DXGI_ModeDesc
                (
                  Self.ClientWidth, Self.ClientHeight,
                  DXGI_Rational_(60, 1),
                  DXGI_FORMAT_R8G8B8A8_UNORM,
                  DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED,
                  DXGI_MODE_SCALING_UNSPECIFIED
                ),
                DXGI_SampleDesc(nSelectedMsaa, 0),
                Self.Handle, TRUE, 1,
                DXGI_USAGE_RENDER_TARGET_OUTPUT,
                DXGI_SWAP_EFFECT_DISCARD,
                0
              ),
              pSwapChain
            );

      if ( Failed(hr) ) then
      begin
        //TFormMain(Owner).StatusBar.Panels[0].Text := 'pSwapChain.ResizeBuffers(): ' + QuotedStr(SysErrorMessage(hr));
        Exit;
      end;

      hr := pDXGIfactory.MakeWindowAssociation(Self.Handle, DXGI_MWA_NO_WINDOW_CHANGES);

      if ( Failed(hr) ) then
        //TFormMain(Owner).StatusBar.Panels[0].Text := 'pDXGIfactory.MakeWindowAssociation(): ' + QuotedStr(SysErrorMessage(hr));
    end;

    hr := pSwapChain.GetBuffer(0, ID3D11Texture2D, pBackBuffer);
    if ( Failed(hr) ) then
    begin
      //TFormMain(Owner).StatusBar.Panels[0].Text := 'pSwapChain.GetBuffer(): ' + QuotedStr(SysErrorMessage(hr));
      Exit;
    end;

    hr := pD3Ddevice.CreateRenderTargetView(pBackBuffer, nil, pRenderTargetView);
    if ( Failed(hr) ) then
    begin
      //TFormMain(Owner).StatusBar.Panels[0].Text := 'pD3DDevice.CreateRenderTargetView(): ' + QuotedStr(SysErrorMessage(hr));
      Exit;
    end;

    pD3Dcontext.OMSetRenderTargets(1, @pRenderTargetView, nil);

    vpDesc.Width := Self.ClientWidth;
    vpDesc.Height := Self.ClientHeight;
    vpDesc.MinDepth := 0.0;
    vpDesc.MaxDepth := 1.0;
    vpDesc.TopLeftX := 0;
    vpDesc.TopLeftY := 0;

    pD3Dcontext.RSSetViewports(1, @vpDesc);

    bInitComplete := TRUE;

    InvalidateRect(Self.Handle, nil, FALSE);
  finally
    inherited Resize();
  end;
end;

procedure TRenderPanel.Paint();
var
  hr: HRESULT;
  cbBuf: TConstantBufferData;
  dwMS: Int64;
  sTextFPS: string;
  msrData: D3D11_MAPPED_SUBRESOURCE;
begin
  if ( not bInitComplete ) then
  begin
    inherited Paint();
    Exit;
  end;

  if {( TFormMain(Owner).actRenderVSync.Checked )}true then
  begin
    hr := pDXGIoutput.WaitForVBlank();

    //if ( Failed(hr) ) then
    //  TFormMain(Owner).StatusBar.Panels[0].Text := 'pDXGIoutput.WaitForVBlank(): ' + QuotedSTr(SysErrorMessage(hr));
  end;

  ZeroMemory(@cbBuf, SizeOf(cbBuf));

  {cbBuf.matView := MatrixLookToLH
                   (
                     D3D_Vector ( 0.0,  0.0, -5.0 ),
                     D3D_Vector ( 0.0,  0.0,  5.0 ),
                     D3D_Vector ( 0.0,  1.0,  0.0 )
                   );
  cbBuf.matProjection := MatrixPerspectiveFovLH
                         (
                           1.0, 0.65, 1.0, 100.0
                         );
  cbBuf.matWorld := D3D_Matrix_Identity();

  cbBuf.matResult := MatrixMultiply
                     (
                       cbBuf.matWorld,
                       MatrixMultiply
                       (
                         cbBuf.matView,
                         cbBuf.matProjection
                       )
                     );}

  cbBuf.matView := D3D_Matrix_Transpose(cbBuf.matView);
  cbBuf.matProjection := D3D_Matrix_Transpose(cbBuf.matProjection);
  cbBuf.matWorld := D3D_Matrix_Transpose(cbBuf.matWorld);
  cbBuf.matResult := D3D_Matrix_Transpose(cbBuf.matResult);

  cbBuf.dwGetTickCount := GetTickCount();
  cbBuf.dwTimeInterval := ( cbBuf.dwGetTickCount - dwTicksOfLastRender );

  dwTicksOfLastRender := cbBuf.dwGetTickCount;

  hr := pD3Dcontext.Map(pConstantBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, msrData);
  if ( Succeeded(hr) ) then
  try
    CopyMemory(msrData.pData, @cbBuf, SizeOf(cbBuf));
  finally
    pD3Dcontext.Unmap(pConstantBuffer, 0);
  end;

  //if ( Failed(hr) ) then
  //  TFormMain(Owner).StatusBar.Panels[0].Text := 'pD3Dcontext.Map(): ' + QuotedStr(SysErrorMessage(hr));

  pD3Dcontext.ClearRenderTargetView(pRenderTargetView, D3D11_RGBA_FLOAT(0, 0, 0, 1.0));

    pD3Dcontext.RSSetState(pRasterizerState);
    pD3Dcontext.IASetInputLayout(pInputLayout);
    pD3Dcontext.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    pD3Dcontext.IASetVertexBuffers(0, 1, @pVertexBuffer, @strides, @offsets);
    pD3Dcontext.IASetIndexBuffer(nil, DXGI_FORMAT_UNKNOWN, 0);
    pD3Dcontext.VSSetConstantBuffers(0, 1, @pConstantBuffer);
    pD3Dcontext.VSSetShader(pVertexShader, nil, 0);
    pD3Dcontext.PSSetConstantBuffers(0, 1, @pConstantBuffer);
    pD3Dcontext.PSSetShader(pPixelShader, nil, 0);

    pD3Dcontext.Draw(3, 0);

  hr := pSwapChain.Present(0, 0);

  //if ( Failed(hr) ) then
  //  TFormMain(Owner).StatusBar.Panels[0].Text := 'SwapChain.Present(): ' + QuotedStr(SysErrorMessage(hr));

  nFrames := nFrames + 1;

  {dwMS := abs(MilliSecondsBetween(dtFrames, Now()));
  if ( dwMS >= 1000 ) then
  begin
    nLastFPS := ( nFrames * 1000.0 / dwMS );
    dtFrames := Now();
    nFrames := 0;

    if ( nLastFPS > 0 ) then
    begin
      if ( nLastFPS >= 20 )
        then sTextFPS := IntToStr(Round(nLastFPS))
        else sTextFPS := FormatFloat('0.0#', nLastFPS);

      sTextFPS := sTextFPS + ' fps';
    end
    else
      sTextFPS := '- fps';

    TFormMain(Owner).StatusBar.Panels[1].Text := sTextFPS;
  end;}
end;




function TDX11ViewArea.CreateRC(_maxdetail:GDBBoolean=false):TDrawContext;
begin
  result:=inherited CreateRC(_maxdetail);
  result.MaxWidth:={OpenGLParam.RD_MaxWidth}100;
end;
procedure TOGLWnd.EraseBackground(DC: HDC);
begin
end;
function TDX11ViewArea.getParam;
begin
     result:=@OpenGLParam;
end;

function TDX11ViewArea.getParamTypeName;
begin
     result:='PTDXData';
end;
procedure TDX11ViewArea.GDBActivateGLContext;
begin
                                      //OpenGLWindow.MakeCurrent;
                                      drawer.delmyscrbuf;
end;
function TDX11ViewArea.NeedDrawInsidePaintEvent:boolean;
begin
     result:=false;
end;

procedure TDX11ViewArea.setdeicevariable;
var tarray:array [0..1] of Double;
    p:pansichar;
begin(*
  //programlog.logoutstr('TOGLWnd.SetDeiceVariable',lp_IncPos,LM_Debug);
  debugln('{D+}TOGLWnd.SetDeiceVariable');
  oglsm.myglGetDoublev(GL_LINE_WIDTH_RANGE,@tarray[0]);
  //if assigned(sysvar.RD.RD_MaxLineWidth) then   m,.
  OpenGLParam.RD_MaxLineWidth:=tarray[1];
  oglsm.myglGetDoublev(GL_point_size_RANGE,@tarray[0]);
  //if assigned(sysvar.RD.RD_MaxPointSize) then
  OpenGLParam.RD_MaxPointSize:=tarray[1];
  GDBPointer(p):=oglsm.myglGetString(GL_VENDOR);
  debugln('{I}RD_Vendor:="%s"',[p]);
  //programlog.LogOutFormatStr('RD_Vendor:="%s"',[p],0,LM_Info);
  //if assigned(OpenglParam.RD_Vendor) then
  OpenglParam.RD_Vendor:=p;
  GDBPointer(p):=oglsm.myglGetString(GL_RENDERER);
  debugln('{I}RD_Renderer:="%s"',[p]);
  //programlog.LogOutFormatStr('RD_Renderer:="%s"',[p],0,LM_Info);
  //if assigned(OpenglParam.RD_Renderer) then
  OpenglParam.RD_Renderer:=p;
  GDBPointer(p):=oglsm.myglGetString(GL_VERSION);
  debugln('{I}RD_Version:="%s"',[p]);
  //programlog.LogOutFormatStr('RD_Version:="%s"',[p],0,LM_Info);
  //if assigned(OpenglParam.RD_Version) then
  OpenglParam.RD_Version:=p;

  GDBPointer(p):=oglsm.myglGetString(GL_EXTENSIONS);
  debugln('{I}RD_Extensions:="%s"',[p]);
  //programlog.LogOutFormatStr('RD_Extensions:="%s"',[p],0,LM_Info);
  //if assigned(OpenglParam.RD_Extensions) then
  OpenglParam.RD_Extensions:=p;
  //if assigned(sysvar.RD.RD_MaxWidth) and assigned(sysvar.RD.RD_MaxLineWidth) then
  begin
  OpenGLParam.RD_MaxWidth:=round(min(OpenGLParam.RD_MaxPointSize,OpenGLParam.RD_MaxLineWidth));
  debugln('{I}RD_MaxWidth:="%G"',[min(OpenGLParam.RD_MaxPointSize,OpenGLParam.RD_MaxLineWidth)]);
  //programlog.LogOutFormatStr('RD_MaxWidth:="%G"',[min(sysvar.RD.RD_MaxPointSize^,sysvar.RD.RD_MaxLineWidth^)],0,LM_Info);
  end;
  //programlog.logoutstr('end;',lp_DecPos,LM_Debug);
  debugln('{D-}TOGLWnd.SetDeiceVariable');*)
end;

procedure TDX11ViewArea.getareacaps;
{$IFDEF LCLGTK2}
var
   Widget:PGtkWidget;
{$ENDIF}
begin
  if VerboseLog^ then
    debugln('{D+}TOGLWnd.InitOGL');
  //programlog.logoutstr('TOGLWnd.InitOGL',lp_IncPos,LM_Debug);
  {$IFDEF LCLGTK2}
  Widget:=PGtkWidget(PtrUInt(OpenGLWindow.Handle));
  gtk_widget_add_events (Widget,GDK_POINTER_MOTION_HINT_MASK);
  {$ENDIF}

  //MywglDeleteContext(OpenGLWindow.OGLContext);//wglDeleteContext(hrc);

  //SetDCPixelFormat(OpenGLWindow.OGLContext);//SetDCPixelFormat(dc);
  //MywglCreateContext(OpenGLWindow.OGLContext);//hrc := wglCreateContext(DC);
  //MyglMakeCurrent(OpenGLWindow.OGLContext);//wglMakeCurrent(DC, hrc);
  //OpenGLWindow.MakeCurrent();
  setdeicevariable;

  {$IFDEF WINDOWS}
  //if assigned(OpenglParam.RD_VSync) then
  (*if OpenglParam.RD_VSync<>T3SB_Default then
  begin
       Pointer(@wglSwapIntervalEXT) := wglGetProcAddress('wglSwapIntervalEXT');
       if @wglSwapIntervalEXT<>nil then
                                           begin
                                                if OpenglParam.RD_VSync=T3SB_True then
                                                                                 wglSwapIntervalEXT(1)
                                                                             else
                                                                                 wglSwapIntervalEXT(0);
                                           end
                                       else
                                           begin
                                                //uzcshared.LogError('wglSwapIntervalEXT not supported by your video driver. Please set the VSync in the defaul');
                                                DebugLn('{EH}wglSwapIntervalEXT not supported by your video driver. Please set the VSync in the defaul');
                                           end;
  end;*)
  {$ENDIF}
  if VerboseLog^ then
    debugln('{D-}end;{TOGLWnd.InitOGL}');
  //programlog.logoutstr('end;{TOGLWnd.InitOGL}',lp_DecPos,LM_Debug);
end;
procedure TDX11ViewArea.DrawGrid;
var
  pg:PGDBvertex2S;
  i,j: GDBInteger;
  v,v1:gdbvertex;
begin
  {//if sysvar.DWG.DWG_DrawGrid<>nil then
  if (pdwg^.DrawGrid)and(param.md.WPPointUR.z=1) then
  begin
  v:=param.md.WPPointBL;
  dc.drawer.SetColor(100, 100, 100, 100);
  pg := @gridarray;
  oglsm.myglbegin(gl_points);
  for i := 0 to round(param.md.WPPointUR.x) do
  begin
       v1:=v;
        for j := 0 to round(param.md.WPPointUR.y) do
        begin
          oglsm.myglVertex3d(v1);
          v1.y:=v1.y+pdwg^.GridSpacing.y;
          inc(pg);
        end;
        v.x:=v1.x-pdwg^.GridSpacing.x;
  end;
  oglsm.myglend;
  end;}
end;

procedure TDX11ViewArea.LightOn;
var
   p:GDBvertex4F;
begin
    if sysvarRDLight
    then
      begin
        {oglsm.myglEnable(GL_LIGHTING);
        oglsm.myglEnable(GL_LIGHT0);
        oglsm.myglEnable (GL_COLOR_MATERIAL);

        p.x:=PDWG.Getpcamera^.prop.point.x;
        p.y:=PDWG.Getpcamera^.prop.point.y;
        p.z:=PDWG.Getpcamera^.prop.point.z;
        p.w:=0;
        oglsm.myglLightfv(GL_LIGHT0,GL_POSITION,@p) ;
        oglsm.myglMaterialf(GL_FRONT_AND_BACK,GL_SHININESS,50.000000);
        p.x:=0;
        p.y:=0;
        p.z:=0;
        p.w:=1;
        oglsm.myglMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR,@p);
        oglsm.myglLightModeli(GL_LIGHT_MODEL_TWO_SIDE,1);
        oglsm.myglColorMaterial(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE);
        oglsm.myglEnable(GL_COLOR_MATERIAL);}
      end
    else
        LightOff(dc);
end;
procedure TDX11ViewArea.LightOff;
begin
    {oglsm.myglDisable(GL_LIGHTING);
    oglsm.myglDisable(GL_LIGHT0);
    oglsm.myglDisable(GL_COLOR_MATERIAL);}
end;
procedure TDX11ViewArea.SwapBuffers(var DC:TDrawContext);
begin
     inherited;
     //OpenGLWindow.SwapBuffers;
end;
function TDX11ViewArea.CreateWorkArea(TheOwner: TComponent):TCADControl;
begin
     result:=TCADControl(TOGLWnd.Create(TheOwner));
end;
procedure TDX11ViewArea.CreateDrawer;
begin
     drawer:=TZGLDXDrawer.Create;
end;
procedure TDX11ViewArea.SetupWorkArea;
begin
     OpenGLWindow:=TOGLWnd(WorkArea);
     OpenGLWindow.wa:=self;
     {if assigned(sysvar.RD.RD_RemoveSystemCursorFromWorkArea) then}
                                                                  RemoveCursorIfNeed(OpenGLWindow,sysvarRDRemoveSystemCursorFromWorkArea);
                                                              {else
                                                                  RemoveCursorIfNeed(OpenGLWindow,true);}
     OpenGLWindow.ShowHint:=true;
     //fillchar(myscrbuf,sizeof(tmyscrbuf),0);

     {$if FPC_FULlVERSION>=20701}
     //OpenGLWindow.AuxBuffers:=0;
     //OpenGLWindow.StencilBits:=8;
     //OpenGLWindow.ColorBits:=24;
     //OpenGLWindow.DepthBits:=24;
     {$ENDIF}
     OpenGLWindow.onpaint:=mypaint;
end;
procedure TDX11ViewArea.WaResize(sender:tobject);
begin
     inherited;
     //OpenGLWindow.MakeCurrent(false);
     param.lastonmouseobject:=nil;

     //self.MakeCurrent(false);
     //isOpenGLError;

     calcoptimalmatrix;
     calcgrid;

     {переделать}//inherited size{(fwSizeType,nWidth,nHeight)};

     //drawer.WorkAreaResize(getviewcontrol.clientwidth,getviewcontrol.clientheight);

     {wa.param.md.glmouse.y := clientheight-wa.param.md.mouse.y;
     CalcOptimalMatrix;
     mouseunproject(wa.param.md.GLmouse.x, wa.param.md.GLmouse.y);
     CalcMouseFrustum;}

     //if param.pglscreen <> nil then
     //GDBFreeMem(param.pglscreen);
     //GDBGetMem({$IFDEF DEBUGBUILD}'ScreenBuf',{$ENDIF}param.pglscreen, getviewcontrol.clientwidth * getviewcontrol.clientheight * 4);

     param.firstdraw := true;
     //draw;
     //paint;
     getviewcontrol.Invalidate;
end;
begin
  RegisterBackend(TDX11ViewArea,'DirectX11');
end.
