#define _CRT_SECURE_NO_WARNINGS
#include <Kydo.h>
#include <thread>
#include <cstdlib>
#include <algorithm>

#define PI 3.1415926535f

int main()
{
	{
		std::string src;
		{
			FILE *fs = fopen("Test.cl", "rb");
			fseek(fs, 0, SEEK_END);
			long len = ftell(fs);
			src.resize(len);
			rewind(fs);
			fread(src.data(), 1, len, fs);
			fclose(fs);
		}

		Kydo::Window wnd(L"Kydo Test", 512, 512);
		auto renderer = Kydo::Renderer::Create(wnd, src);
		if (renderer->IsAlive())
		{
			wnd.Clear(renderer);
			std::vector<Kydo::Vertex> verts = {
				{ 128, 384, 0xFFFF00, },
				{ 384, 384, 0x00FF00, },
				{ 384, 128, 0x00FFFF, },
				{ 128, 128, 0xFF0000, },
			};
			std::vector<Kydo::Indice> indices = {
				0, 1, 2,
				0, 2, 3,
			};

			wnd.Show();
			while (wnd.IsAlive() && renderer->IsAlive())
			{
				wnd.Update();
				wnd.Clear(renderer);
				renderer->Render(verts, indices);
				wnd.Render(renderer);
				using namespace std::chrono_literals;
				std::this_thread::sleep_for(50ms);
			}
			wnd.Destroy();
		}
	}

	std::system("pause");
}