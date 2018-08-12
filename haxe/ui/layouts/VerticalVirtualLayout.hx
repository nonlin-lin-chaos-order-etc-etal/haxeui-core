package haxe.ui.layouts;

import haxe.ui.containers.IVirtualContainer;
import haxe.ui.core.Component;

class VerticalVirtualLayout extends VirtualLayout {
    private override function repositionChildren() {
        super.repositionChildren();

        var comp:IVirtualContainer = cast(_component, IVirtualContainer);
        var usableSize = this.usableSize;
        var contents:Component = this.contents;
        var verticalSpacing = contents.layout.verticalSpacing;
        var itemHeight = comp.itemHeight;
        if (comp.virtual == true) {
            var n:Int = _firstIndex;
            if (comp.variableItemSize == true) {
                var pos:Float = -comp.vscrollPos;
                for (i in 0..._lastIndex) {
                    if (i >= _firstIndex) {
                        var c:Component = contents.getComponentAt(i - _firstIndex);
                        c.top = pos;
                    }

                    var size:Null<Float> = _sizeCache[i];
                    pos += (size != null && size != 0 ? size : itemHeight) + verticalSpacing;
                }
            } else {
                for (child in contents.childComponents) {
                    child.top = (n * (itemHeight + verticalSpacing)) - comp.vscrollPos;
                    ++n;
                }
            }
        } else {
            /* VBOX CAN DO THIS
            var n:Int = 0;
            var y:Float = 0;
            for (child in contents.childComponents) {
                itemHeight = child.height;
                if (itemHeight == 0) { // TODO: is this a good idea??
                    child.syncComponentValidation();
                    itemHeight = child.height;
                }
                child.top = y;
                y += itemHeight + verticalSpacing;
                ++n;
            }
            */
        }
    }

    private override function calculateRangeVisible() {
        var comp:IVirtualContainer = cast(_component, IVirtualContainer);
        var verticalSpacing = contents.layout.verticalSpacing;
        var itemHeight = comp.itemHeight;
        var visibleItemsCount:Int = 0;
        var contentsHeight:Float = contents.height;
        if (contentsHeight > _component.height) {
            contentsHeight = _component.height;
        }

        if (comp.variableItemSize == true) {
            var totalSize:Float = 0;
            var requireInvalidation:Bool = false;
            var newFirstIndex:Int = -1;
            for (i in 0...dataSource.size) {
                var size:Null<Float> = _sizeCache[i];

                //Extract the itemrenderer size from the cache or child component
                if (size == null || size == 0) {
                    if (isIndexVisible(i)) {
                        var c:Component = contents.getComponentAt(i - _firstIndex);
                        if (c != null && c.componentHeight > 0) {
                            _sizeCache[i] = c.componentHeight;
                            size = c.componentHeight;
                        } else {
                            requireInvalidation = true;
                            size = itemHeight;
                        }
                    } else {
                        requireInvalidation = true;
                        size = itemHeight;
                    }
                }

                size += verticalSpacing;

                //Check limits
                if (newFirstIndex == -1) {      //Stage 1 - find the first index
                    if (totalSize + size > comp.vscrollPos) {
                        newFirstIndex = i;
                        totalSize += size - comp.vscrollPos;
                        ++visibleItemsCount;
                    } else {
                        totalSize += size;
                    }
                } else {                        //Stage 2 - find the visible items count
                    if (totalSize + size > contentsHeight) {
                        break;
                    } else {
                        ++visibleItemsCount;
                        totalSize += size;
                    }
                }
            }

            if (requireInvalidation == true) {
                _component.invalidateComponentLayout();
            }

            _firstIndex = newFirstIndex;
        } else {
            visibleItemsCount = Math.ceil(contentsHeight / (itemHeight + verticalSpacing));
            _firstIndex = Std.int(comp.vscrollPos / (itemHeight + verticalSpacing));
        }

        if (_firstIndex < 0) {
            _firstIndex = 0;
        }

        _lastIndex = _firstIndex + visibleItemsCount + 1;
        if (_lastIndex > dataSource.size) {
            _lastIndex = dataSource.size;
        }
    }

    private override function updateScroll() {
        var comp:IVirtualContainer = cast(_component, IVirtualContainer);
        var usableSize = this.usableSize;
        var dataSize:Int = dataSource.size;
        var verticalSpacing = contents.layout.verticalSpacing;
        var itemHeight = comp.itemHeight;
        var scrollMax:Float = 0;

        if (comp.variableItemSize == true) {
            scrollMax = -usableSize.height;
            for (i in 0...dataSource.size) {
                var size:Null<Float> = _sizeCache[i];
                if (size == null || size == 0) {
                    size = itemHeight;
                }

                scrollMax += size + verticalSpacing;
            }
        } else {
            scrollMax = (dataSize * itemHeight + ((dataSize - 1) * verticalSpacing)) - usableSize.height;
        }

        if (scrollMax < 0) {
            scrollMax = 0;
        }

        comp.vscrollMax = scrollMax;
        comp.vscrollPageSize = (usableSize.height / (scrollMax + usableSize.height)) * scrollMax;
    }
}