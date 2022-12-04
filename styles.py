#! /usr/bin/env python3

''''''

from collections import UserString
import unittest

class Text(UserString):

    _dim  = '\033[2m'  # 242
    _blue = '\033[34m' # 69: dir blue
    _red  = '\033[31m'
    _res  = '\033[0m'
    _b    = '\033[1m'
    _i    = '\033[3m'
    _u    = '\033[4m'

    def __init__(self, text=''):
        if isinstance(text, dict):
            super().__init__(text['styles'] + text['text'] + self._res)
        else:
            super().__init__(text)
        self._text = text

    def style(self, style):
        if isinstance(self._text, dict):
            styles = self._text['styles'] + style
            text = self._text['text']
        else:
            styles = style
            text = self._text
        return Text({'styles': styles, 'text': text})

    @property
    def red(self):
        return self.style(Text._red)

    @red.setter
    def red(self, value):
        Text._red = f'\033[38;5;{value}m'

    @property
    def blue(self):
        return self.style(Text._blue)

    @blue.setter
    def blue(self, value):
        Text._blue = f'\033[38;5;{value}m'

    # bold, underline, italic
    @property
    def b(self):
        return self.style(Text._b)

    @property
    def u(self):
        return self.style(Text._u)

    @property
    def i(self):
        return self.style(Text._i)

    def __eq__(self, other):
        if isinstance(self._text, dict):
            return self._text['text'] == other
        else:
            return self._text == other

class TestMethods(unittest.TestCase):

    def test_eq(self):
        self.assertEqual(Text('Hello World').red, 'Hello World')
        self.assertEqual(Text('Hello World').red.b, 'Hello World')

if __name__  == "__main__":

    print('-', Text(), '-')
    print(Text('Hello'))
    print(Text('Hello').red)
    print(Text('Hello').red.b)
    print(Text('Hello').red.b.u)
    print(Text('Hello').red.b.u.i)
    print(Text('Hello').red.b.u.i, 'World')
    print(Text('/etc/fstab').blue)
    Text().red = 42
    print(f"{Text('Hello').red.b.u} World {Text('!!').b}")
    print(Text('Hello World').rjust(35, '>'))
    print(Text('Hello World').red.rjust(35, '>'))
    print(repr(Text('Hello World').red.b._text['styles']))

    unittest.main()
