---
layout: post
title: Windows 창 투명화 프로그램
tags: ['windows', 'transparent', 'winapi', 'layerwindow']
---

[Download](/file/layerwindowv1_2.zip) \| [GitHub](//github.com/lastone9182/layerwindowtray)

Windows 10에서 현재 활성화 되지 않은 윈도우를 투명하게 하는 프로그램입니다.

활성화 창 투명도: 90%, 비활성화 창 투명도: 50%

![layerwindow](/image/layerwindow/layerwindow_v1.png)

~~아직은 핵심 기능만 구현한 것이며 추후 트레이 아이콘으로 백그라운드 프로세스로 만들 계획입니다.~~

[현재 패치](//github.com/lastone9182/layerwindowtray#2017-1-19-patch)

- - -

터미널을 투명하게 할 수 있다면 다른 창도 투명하게 할 수 있겠지?  
이런 궁금증으로 만들어 본 프로그램입니다.

간단하게 다른 프로그램의 창의 정보를 얻어서 바꾸면 됩니다.
하지만 창의 정보를 얻는 것과 바꾼다는 일이 쉽지가 않았습니다.

이런 정보를 얻기 위해 Visual Studio에서 창의 정보를 얻기 위해
[spy++](//msdn.microsoft.com/ko-kr/library/dd460756.aspx)를 제공합니다.

실행을 해보면 창 캡션(제목), 핸들, 영역 및 세부 정보를 얻을 수 있게 됩니다.

![spy++](/image/layerwindow/spypp.png)

이들을 제어하기 위해서는 Windows API를 사용해야 합니다.

저는 Windows API를 **사용만** 해보았습니다.
학부에서 잠깐 배운 정도 밖에 되지 않기 때문에 새로 만들게 되었습니다.

다행히 Visual Studio 2015에서는 기본적인 Windows Application을 만들기 위한 템플릿이 있었습니다.

필요한 부분만 구현하면 될 정도였습니다.

## Transparent Windows

[Layered Windows 참고](//msdn.microsoft.com/en-us/library/ms997507.aspx)

창 투명화를 위한 핵심적인 코드는 다음과 같습니다.

```c++
// Set WS_EX_LAYERED on this Windows
SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) | WS_EX_LAYERED);
// Make this window 70% alpha
SetLayeredWindowAttributes(hWnd, 0, (255 * 70) / 100, LWA_ALPHA);
```

SPY++ 에서 창에 대한 정보를 얻을 수 있다고 했습니다.
위 코드는 `SetWindowLong`을 통해 `LONG` 값에 해당하는 창에 `WS_EX_LAYERED` 상수를 부여해주며
`SetLayeredWindowAttributes`를 통해 해당 창의 알파값을 변경하는 것입니다.

그러면 이제 `hWnd`를 얻을 수만 있다면 해당하는 창의 투명도를 자유자재로 변경할 수 있을 것입니다.

## Get Active HWND

특정 `hWnd`를 얻으려면

[FindWindow](//msdn.microsoft.com/en-us/library/windows/desktop/ms633499.aspx)
같은 함수로 얻을 수 있습니다.

이 함수는 특정 `class_name(창 클래스 이름)`과 `windowname(제목 캡션 이름)`이 필요합니다.
`NULL`로 지정하면 해당 클래스나 제목을 모두 찾게됩니다.

저는 활성화 된 창과 그렇지 않은 창만 구별하기 위해 위 함수는 필요가 없었습니다.
좀 더 정교한 프로그램을 만들기 위해 필요한 함수 같습니다.

그래서 현재 활성화 된 창을 얻기 위해 [GetForegroundWindow](https://msdn.microsoft.com/en-us/library/windows/desktop/ms633505.aspx)
함수를 사용했습니다. 이는 단순히 현재 활성화된 `hWnd`만을 반환하게 됩니다.

## EnumWindows

이제 모든 열린 창들을 반투명하게 만들고 활성화 된 창만 불투명하게 만들어 보려고합니다.
하지만 모든 창들을 구하기 위해서 각각의 `hWnd`를 구할 수 있는 방법을 찾아야 합니다.

앞서 `hWnd`를 얻는 과정에서 `FindWindow`의 창 클래스나 제목 캡션이름을 `NULL`로 설정할 경우 모든 부분을 찾는 다고 했습니다.
하지만 `FindWindow(NULL, NULL)`로 찾아 봐야 `HWND`의 배열을 반환하지도 않을 뿐더러 충돌이 일어날 가능성도 높아집니다.

`EnumWindows`는 `CALLBACK` 함수를 인자로 다음과 같이 모든 `hWnd`를 순회할 수 있게 해줍니다.

```c++
BOOL CALLBACK EnumWindowsProc(HWND hWnd, LPARAM lparam)
{
    ...
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    ...

    // All Windows Iteration
    EnumWindows(EnumWindowsProc, NULL);

    ...
}
```

`EnumWindowsProc`에서 모든 `hWnd`를 차례로 호출하기 때문에 여기서 불필요한 창을 거르고
`GetForegroundWindow`를 통해 현재 활성화된 창을 추출할 수 있게됩니다.

## Source Code

다음은 최종 코드의 일부이며 자세한 내용은 GitHub의 [layerwindowtray.cpp](//github.com/lastone9182/layerwindowtray/blob/master/layerwindowtray.cpp)
를 참조하시길 바랍니다.

```c++
// 전역변수
HWND hWndOld, hWndActive;						// 활성화된 창 저장
UINT const WMAPP_NOTIFYCALLBACK = WM_APP + 1;	// 사용자정의 콜백함수
POINT gpt;				                        // 마우스
int ACTIVE = 90;
int INACTIVE = 50;

// 타이머마다 호출되는 콜백함수
BOOL CALLBACK EnumWindowsProc(HWND hWnd, LPARAM lparam) {
    // 안 보이는 창 필터링
    if (!IsWindowVisible(hWnd)) {
        return TRUE;
    }
    // 부모가 바탕화면인지
    if (GetParent(hWnd) != 0) {
        return TRUE;
    }
    // 최소화된 창 건너뛰기
    if (IsIconic(hWnd)) {
        return TRUE;
    }
    // 마우스 영역 추출
    RECT rt;
    GetWindowRect(hWnd, &rt);

    try
    {
        // set WS_EX_LAYERED on this Window
        SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) | WS_EX_LAYERED);
        // Current active windows ALPHA ACTIVE%, else windows INACTIVE%
        if (hWnd == hWndActive | IsCurInRect(rt)) {
            SetLayeredWindowAttributes(hWnd, 0, (255 * ACTIVE) / 100, LWA_ALPHA);
        }
        else {
            SetLayeredWindowAttributes(hWnd, 0, (255 * INACTIVE) / 100, LWA_ALPHA);
        }
    }
    catch (...)
    {
        return FALSE;
    }
    return TRUE;
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_CREATE:
    {
        // Initialization
        // Get Current Active Window
        hWndActive = GetForegroundWindow();
        // All Windows Iteration
        EnumWindows(EnumWindowsProc, NULL);
        // Old Pointer
        hWndOld = GetForegroundWindow();

        // add the notification icon
        if (!AddNotificationIcon(hWnd))
        {
            MessageBox(hWnd,
                L"Please read the ReadMe.txt file for troubleshooting",
                L"Error adding icon", MB_OK);
            return -1;
        }

        // add the notification popup
        AddNotificationPopup(hWnd);


        SetTimer(hWnd,						// handle to main window
            1,								// timer identifier
            200,							// 0.2-second interval
            (TIMERPROC)NULL);               // no timer callback
    }
    break;
    case WM_COMMAND:
    {
        // MENU ID <<====>> COMMAND
    }
    break;
	case WM_TIMER:
	{
        // Get Current Active Window
		hWndActive = GetForegroundWindow();

		// Get Mouse Capture Window
		GetCursorPos(&gpt);

		// All Windows Iteration
		EnumWindows(EnumWindowsProc, NULL);

        // Old Pointer
		hWndOld = hWndActive;
	}
    break;
    case WMAPP_NOTIFYCALLBACK:
    {
        switch (lParam)
        {
        case WM_CONTEXTMENU:
        {
            ShowContextMenu(hWnd, gpt);
        }
        break;
        }
    }
    break;
    case WM_DESTROY:
        EnumWindows(EnumWindowsProcBack, NULL);
        KillTimer(hWnd, 1);
        DeleteNotificationIcon();
        DestroyWindow(hWnd);
        PostQuitMessage(0);
        break;
    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
}
```

트레이 아이콘을 추가하여 백그라운드 프로세스로 실행할 수 있고 마우스 좌표를 얻어 창 영역으로 들어가게 되었을 때의 창 투명도를 변환을 추가하였습니다.
