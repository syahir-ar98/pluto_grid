import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

typedef PlutoTripleOnSelectedEventCallback = void Function(
    PlutoTripleOnSelectedEvent event);

class PlutoTripleGrid extends StatefulWidget {
  final PlutoTripleGridProps gridPropsA;

  final PlutoTripleGridProps gridPropsB;

  final PlutoTripleGridProps gridPropsC;

  final PlutoGridMode? mode;

  final PlutoTripleOnSelectedEventCallback? onSelected;

  /// [PlutoTripleGridDisplayRatio]
  /// Set the width of the two grids by specifying the ratio of the left grid.
  /// 0.5 is 5(left grid):5(right grid).
  /// 0.8 is 8(left grid):2(right grid).
  ///
  /// [PlutoTripleGridDisplayFixedAndExpanded]
  /// Fix the width of the left grid.
  ///
  /// [PlutoTripleGridDisplayExpandedAndFixed]
  /// Fix the width of the right grid.
  final PlutoTripleGridDisplay display;

  const PlutoTripleGrid({
    required this.gridPropsA,
    required this.gridPropsB,
    required this.gridPropsC,
    this.mode,
    this.onSelected,
    this.display = const PlutoTripleGridDisplayRatio(),
    Key? key,
  }) : super(key: key);

  @override
  _PlutoTripleGridState createState() => _PlutoTripleGridState();
}

class _PlutoTripleGridState extends State<PlutoTripleGrid> {
  PlutoGridStateManager? _stateManagerA;

  PlutoGridStateManager? _stateManagerB;

  PlutoGridStateManager? _stateManagerC;

  Widget _buildGrid({
    required PlutoTripleGridProps props,
    required PlutoGridMode? mode,
    required double width,
    required _GridPosition gridPosition,
  }) {
    return SizedBox(
      width: width,
      child: PlutoGrid(
        columns: props.columns,
        rows: props.rows,
        mode: mode,
        onLoaded: (PlutoGridOnLoadedEvent onLoadedEvent) {
          switch (gridPosition) {
            case _GridPosition.a:
              _stateManagerA = onLoadedEvent.stateManager;
              break;
            case _GridPosition.b:
              _stateManagerB = onLoadedEvent.stateManager;
              break;
            case _GridPosition.c:
              _stateManagerC = onLoadedEvent.stateManager;
              break;
          }

          onLoadedEvent.stateManager.eventManager!
              .listener((PlutoGridEvent plutoEvent) {
            if (plutoEvent is PlutoGridCannotMoveCurrentCellEvent) {
              switch (gridPosition) {
                case _GridPosition.a:
                  if (plutoEvent.direction.isRight) {
                    _stateManagerA!.setKeepFocus(false);
                    _stateManagerB!.setKeepFocus(true);
                    _stateManagerC!.setKeepFocus(false);
                  }
                  break;
                case _GridPosition.b:
                  if (plutoEvent.direction.isRight) {
                    _stateManagerA!.setKeepFocus(false);
                    _stateManagerB!.setKeepFocus(false);
                    _stateManagerC!.setKeepFocus(true);
                  } else if (plutoEvent.direction.isLeft) {
                    _stateManagerA!.setKeepFocus(true);
                    _stateManagerB!.setKeepFocus(false);
                    _stateManagerC!.setKeepFocus(false);
                  }
                  break;
                case _GridPosition.c:
                  if (plutoEvent.direction.isLeft) {
                    _stateManagerA!.setKeepFocus(false);
                    _stateManagerB!.setKeepFocus(true);
                    _stateManagerC!.setKeepFocus(false);
                  }
                  break;
              }
            }
          });

          if (props.onLoaded != null) {
            props.onLoaded!(onLoadedEvent);
          }
        },
        onChanged: props.onChanged,
        onSelected: (PlutoGridOnSelectedEvent onSelectedEvent) {
          if (onSelectedEvent.row == null || onSelectedEvent.cell == null) {
            widget.onSelected!(
              PlutoTripleOnSelectedEvent(
                gridA: null,
                gridB: null,
                gridC: null,
              ),
            );
          } else {
            widget.onSelected!(
              PlutoTripleOnSelectedEvent(
                gridA: PlutoGridOnSelectedEvent(
                  row: _stateManagerA!.currentRow,
                  cell: _stateManagerA!.currentCell,
                ),
                gridB: PlutoGridOnSelectedEvent(
                  row: _stateManagerB!.currentRow,
                  cell: _stateManagerB!.currentCell,
                ),
                gridC: PlutoGridOnSelectedEvent(
                  row: _stateManagerC!.currentRow,
                  cell: _stateManagerC!.currentCell,
                ),
              ),
            );
          }
        },
        createHeader: props.createHeader,
        createFooter: props.createFooter,
        configuration: props.configuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, size) {
      return Row(
        children: [
          _buildGrid(
            props: widget.gridPropsA,
            mode: widget.mode,
            width: widget.display.gridAWidth(size),
            gridPosition: _GridPosition.a,
          ),
          _buildGrid(
            props: widget.gridPropsB,
            mode: widget.mode,
            width: widget.display.gridBWidth(size),
            gridPosition: _GridPosition.b,
          ),
          _buildGrid(
            props: widget.gridPropsC,
            mode: widget.mode,
            width: widget.display.gridCWidth(size),
            gridPosition: _GridPosition.c,
          ),
        ],
      );
    });
  }
}

class PlutoTripleOnSelectedEvent {
  PlutoGridOnSelectedEvent? gridA;
  PlutoGridOnSelectedEvent? gridB;
  PlutoGridOnSelectedEvent? gridC;

  PlutoTripleOnSelectedEvent({
    this.gridA,
    this.gridB,
    this.gridC,
  });
}

abstract class PlutoTripleGridDisplay {
  double gridAWidth(BoxConstraints size);

  double gridBWidth(BoxConstraints size);

  double gridCWidth(BoxConstraints size);
}

class PlutoTripleGridDisplayRatio implements PlutoTripleGridDisplay {
  final double ratio;

  const PlutoTripleGridDisplayRatio({
    this.ratio = 0.5,
  }) : assert(0 < ratio && ratio < 1);

  @override
  double gridAWidth(BoxConstraints size) => size.maxWidth * ratio;

  @override
  double gridBWidth(BoxConstraints size) => size.maxWidth * (1 - ratio) / 2;

  @override
  double gridCWidth(BoxConstraints size) => size.maxWidth * (1 - ratio) / 2;
}

class PlutoTripleGridDisplayFixedAndExpanded implements PlutoTripleGridDisplay {
  final double width;

  const PlutoTripleGridDisplayFixedAndExpanded({
    this.width = 206.0,
  });

  @override
  double gridAWidth(BoxConstraints size) => width;

  @override
  double gridBWidth(BoxConstraints size) => (size.maxWidth - width) / 2;

  @override
  double gridCWidth(BoxConstraints size) => (size.maxWidth - width) / 2;
}

class PlutoTripleGridDisplayExpandedAndFixed implements PlutoTripleGridDisplay {
  final double width;

  const PlutoTripleGridDisplayExpandedAndFixed({
    this.width = 206.0,
  });

  @override
  double gridAWidth(BoxConstraints size) => size.maxWidth - (width * 2);

  @override
  double gridBWidth(BoxConstraints size) => width;

  @override
  double gridCWidth(BoxConstraints size) => width;
}

class PlutoTripleGridProps {
  final List<PlutoColumn> columns;
  final List<PlutoRow> rows;
  final PlutoOnLoadedEventCallback? onLoaded;
  final PlutoOnChangedEventCallback? onChanged;
  final CreateHeaderCallBack? createHeader;
  final CreateFooterCallBack? createFooter;
  final PlutoGridConfiguration? configuration;

  PlutoTripleGridProps({
    required this.columns,
    required this.rows,
    this.onLoaded,
    this.onChanged,
    this.createHeader,
    this.createFooter,
    this.configuration,
  });

  PlutoTripleGridProps copyWith({
    List<PlutoColumn>? columns,
    List<PlutoRow>? rows,
    PlutoOnLoadedEventCallback? onLoaded,
    PlutoOnChangedEventCallback? onChanged,
    CreateHeaderCallBack? createHeader,
    CreateFooterCallBack? createFooter,
    PlutoGridConfiguration? configuration,
  }) {
    return PlutoTripleGridProps(
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      onLoaded: onLoaded ?? this.onLoaded,
      onChanged: onChanged ?? this.onChanged,
      createHeader: createHeader ?? this.createHeader,
      createFooter: createFooter ?? this.createFooter,
      configuration: configuration ?? this.configuration,
    );
  }
}

enum _GridPosition {
  a,
  b,
  c,
}
