class Interceptor:

    def __init__(self, next):
        self.next = next

    def handle(self, data):
        pass

class Pipeline:

    def __init__(self, root: Interceptor):
        self.head = root
        current = root
        while current.next is not None:
            current = current.next
        self.tail = current
    
    def add(self, index: int, interceptor: Interceptor):
        i = 0
        previous = None
        next = self.head
        while i < index and next is not None:
            previous = next
            next = next.next
            i += 1
        if i == index:
            if previous is not None:
                previous.next = interceptor
            if next is not None:
                interceptor.next = next
        else:
            raise IndexError("Illegal index " + i)
        return self
    
    def handle(self, x):
        self.head.handle(x)
