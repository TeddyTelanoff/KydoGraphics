#include <Kydo.h>
#include <cstdlib>

int main()
{
	Kydo::Window wnd(L"Kydo Test");
	wnd.Show();

	Kydo::Renderer renderer(wnd);

	while (wnd.IsAlive())
		wnd.Update();
	wnd.Destroy();

	std::system("pause");
}